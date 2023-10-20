// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {console2} from "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC3156FlashLender.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract DeFlashLoan is IERC3156FlashLender {
    struct Pool {
        /// @dev The amount of tokens in the pool at this fee level
        uint thisFeeAmount;
        /// @dev The amount of rewards accumulated per token, this is needed to give each user their fair share
        uint rewardPerToken;

        // This becomes a doubly linked list
        uint previousFee;
        uint nextFee;
    }

    /// @dev A struct to store user info
    struct UserInfo {
        uint amount;
        uint rewardDebt;
    }

    event TokenDeposited(address indexed user, address token, uint amount, uint feeLevel);
    event TokenWithdrawn(address indexed user, address token, uint amount, uint feeLevel);
    event FlashLoan(address token, uint amount, uint fee);

    /// @dev Token address => lowest fee amount (start of doubly linked list)
    mapping(address => uint) public lowestFeeAmount;

    /// @dev Token address => total available tokens (to cache this commonly requested value)
    mapping(address => uint) public totalAvailable;

    /// @dev Token address => fee amount => fee pool
    mapping(address => mapping(uint => Pool)) public pools;

    /// @dev User address => token address => fee level => user info
    mapping(address => mapping(address => mapping(uint => UserInfo))) public userInfo;

    /// @dev The fee divisor, thus a fee of 10_000 is 1%
    uint constant public REWARD_FEE_DIVISOR = 1_000_000;

    function deposit(address token, uint amount, uint fee) external {
        // Does fee exist?
        if(pools[token][fee].thisFeeAmount > 0) {
            // Yes: add amount to mapping
            pools[token][fee].thisFeeAmount += amount;
        } else {
            // No: Create mapping, change previousFee and nextFee of previous and next fee
            // Search in pools[token] to find a place to insert in the linked list
            // If this fee is lower than the lowest fee, insert it at the start of the list
            if(fee < lowestFeeAmount[token] || lowestFeeAmount[token] == 0) {
                uint lowestFee = lowestFeeAmount[token];

                // Insert at start of list
                pools[token][fee] = Pool({
                    thisFeeAmount: amount,
                    rewardPerToken: 0,
                    previousFee: 0,
                    nextFee: lowestFee
                });
                // Change previousFee of next fee
                pools[token][lowestFee].previousFee = fee;
                // Change lowestFeeAmount
                lowestFeeAmount[token] = fee;
            } else {
                // Start with the lowest fee in the pool
                uint previousFee = lowestFeeAmount[token];
                // Search for the right place to insert, after this while loop previousFee will be the fee level after the one we want to insert
                while(previousFee < fee && pools[token][previousFee].nextFee != 0) {
                    previousFee = pools[token][previousFee].nextFee;
                }

                // Get next fee
                uint nextFee = pools[token][previousFee].nextFee;

                // Change nextFee of previous fee
                pools[token][previousFee].nextFee = fee;

                // Change previousFee of next fee
                pools[token][nextFee].previousFee = fee;

                // Insert new fee level
                pools[token][fee] = Pool({
                    thisFeeAmount: amount,
                    rewardPerToken: 0,
                    previousFee: previousFee,
                    nextFee: nextFee
                });
            }
        }
        // Save user info
        userInfo[msg.sender][token][fee].amount += amount;
        // Add to total available
        totalAvailable[token] += amount;

        // Take ERC20 tokens from user
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        emit TokenDeposited(msg.sender, token, amount, fee);
    }

    function withdraw(address token, uint amount, uint fee) external {
        // Give user rewards
        distributeRewards(token, fee);

        // Subtract amount from mapping
        pools[token][fee].thisFeeAmount -= amount;
        // Is thisFeeAmount 0?
        if(pools[token][fee].thisFeeAmount == 0) {
            // Yes: Delete mapping, change previousFee and nextFee of previous and next fee
            // Check if this is lowest fee
            if(lowestFeeAmount[token] == fee) {
                // Yes: Change lowestFeeAmount
                lowestFeeAmount[token] = pools[token][fee].nextFee;
                // Change previousFee to 0
                pools[token][lowestFeeAmount[token]].previousFee = 0;
                // Delete to save gas
                delete pools[token][fee];
            } else {
                // TODO: what if it's the last one?
                // No: Change nextFee of previous fee and previousFee of next fee
                uint nextFee = pools[token][fee].nextFee;
                uint previousFee = pools[token][fee].previousFee;

                pools[token][previousFee].nextFee = nextFee;
                // Change previousFee of next fee
                pools[token][nextFee].previousFee = previousFee;
                // Delete to save gas
                delete pools[token][fee];
            }
        }
        // Subtract from total available
        totalAvailable[token] -= amount;

        // Give ERC20 tokens to user
        IERC20(token).transfer(msg.sender, amount);

        emit TokenWithdrawn(msg.sender, token, amount, fee);
    }

    function distributeRewards(address token, uint feeLevel) public returns (uint){
        UserInfo storage user = userInfo[msg.sender][token][feeLevel];
        Pool storage pool = pools[token][feeLevel];

        // Check if user has rewards for token and fee level
        uint rewards = user.amount * (pool.rewardPerToken - user.rewardDebt) / REWARD_FEE_DIVISOR;
        if(rewards == 0) return 0;

        // Subtract from total available
        totalAvailable[token] -= rewards;
        // Subtract from pool amount
        pool.thisFeeAmount -= rewards;
        // Update user info
        user.rewardDebt = pool.rewardPerToken;

        // Transfer rewards to user
        IERC20(token).transfer(msg.sender, rewards);

        return rewards;
    }

    /// @dev The fee level to be charged for a given loan size, also returns the overshoot of the top fee level
    function flashFeeAndOvershoot(address token, uint256 amount) public view returns (uint256, uint256) {
        uint fee = lowestFeeAmount[token];
        uint runningAmount = pools[token][fee].thisFeeAmount;

        // While amount is less than summed amounts, check next fee amount
        while(amount > runningAmount && pools[token][fee].nextFee != 0) {
            // Check next fee amount
            fee = pools[token][fee].nextFee;
            // Update running amount
            runningAmount += pools[token][fee].thisFeeAmount;
        }

        // Is amount less than summed amounts?
        require(amount <= runningAmount, "DeFlashLoan: Not enough liquidity available");

        // Return fee and overshoot of top fee level
        return (fee, runningAmount - amount);
    }

    // #region IERC3156FlashLender

    /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256) {
        return totalAvailable[token];
    }

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token,uint256 amount) public view returns (uint256) {
        (uint feeLevel, ) = flashFeeAndOvershoot(token, amount);
        return feeLevel * amount / REWARD_FEE_DIVISOR;
    }

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes calldata data) external returns (bool) {
        (uint feeLevel, uint overshoot) = flashFeeAndOvershoot(token, amount);
        uint fee = feeLevel * amount / REWARD_FEE_DIVISOR;
        IERC20 erc20 = IERC20(token);

        // Transfer tokens from this contract to the receiver
        require(
            erc20.transfer(address(receiver), amount),
            "DeFlashLoan: Transfer to receiver failed"
        );

        require(
            receiver.onFlashLoan(msg.sender, token, amount, fee, data) == keccak256("ERC3156FlashBorrower.onFlashLoan"),
            "DeFlashLoan: Callback failed"
        );

        // Ensure that the receiver has approved this contract to spend the tokens
        require(
            erc20.allowance(address(receiver), address(this)) >= (amount + fee),
            "DeFlashLoan: Repay not approved"
        );

        // Transfer tokens back from the receiver to this contract
        require(
            erc20.transferFrom(address(receiver), address(this), amount + fee),
            "DeFlashLoan: Transfer from receiver failed"
        );

        // Update rewardPerToken for all used fee levels
        // Start with the lowest fee in the pool
        uint searchFee = lowestFeeAmount[token];
        // Loop until `fee`
        while(searchFee < feeLevel && searchFee != 0) {
            // Update rewardPerToken for this fee level
            pools[token][searchFee].rewardPerToken += fee * REWARD_FEE_DIVISOR / amount;
            pools[token][searchFee].thisFeeAmount += fee * pools[token][searchFee].thisFeeAmount / amount;
            // Get next fee
            searchFee = pools[token][searchFee].nextFee;
        }

        // Update rewardPerToken for `fee`
        if(lowestFeeAmount[token] != feeLevel) {
            pools[token][feeLevel].rewardPerToken += fee * REWARD_FEE_DIVISOR * (pools[token][feeLevel].thisFeeAmount - overshoot) / pools[token][feeLevel].thisFeeAmount / amount;
            pools[token][feeLevel].thisFeeAmount += fee * (pools[token][feeLevel].thisFeeAmount - overshoot) / amount;
        }

        // Update totalAvailable for this token
        totalAvailable[token] += fee;

        emit FlashLoan(token, amount, fee);

        return true;
    }

    // #endregion
}
