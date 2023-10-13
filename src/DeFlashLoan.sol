// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "openzeppelin-contracts/token/ERC1155/ERC1155.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "openzeppelin-contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./IERC3156FlashLender.sol";

contract DeFlashLoan is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply, IERC3156FlashLender {
    struct Pool {
        /// @dev The amount of tokens in the pool at this fee level
        uint thisFeeAmount;
        /// @dev The amount of rewards in the pool that haven't been distributed at this fee level
        uint rewardsToDistribute;
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

    /// @dev Token address => lowest fee amount (start of doubly linked list)
    mapping(address => uint) public lowestFeeAmount;

    /// @dev Token address => total available tokens (to cache this commonly requested value)
    mapping(address => uint) public totalAvailable;

    /// @dev Token address => fee amount => fee pool
    mapping(address => mapping(uint => Pool)) public pools;

    /// @dev User address => token address => fee level => user info
    mapping(address => mapping(address => mapping(uint => UserInfo))) public userInfo;

    constructor(address initialOwner) ERC1155("") Ownable(initialOwner) { }

    function deposit(address token, uint amount, uint fee) external {
        // Does fee exist?
        if(pools[token][fee].thisFeeAmount > 0) {
            // Yes: add amount to mapping
            pools[token][fee].thisFeeAmount += amount;
        } else {
            // No: Create mapping, change previousFee and nextFee of previous and next fee
            // Search in pools[token] to find a place to insert in the linked list
            // Start with the lowest fee in the pool
            uint previousFee = lowestFeeAmount[token];
            // If the lowest fee is higher than the fee we want to insert, insert it at the start of the list
            if(previousFee < fee) {
                // Insert at start of list
                pools[token][fee] = Pool({
                    thisFeeAmount: amount,
                    rewardsToDistribute: 0,
                    rewardPerToken: 0,
                    previousFee: 0,
                    nextFee: previousFee
                });
                // Change previousFee of next fee
                pools[token][previousFee].previousFee = fee;
                // Change lowestFeeAmount
                lowestFeeAmount[token] = fee;
            } else {
                // Search for the right place to insert, after this while loop previousFee will be the fee level after the one we want to insert
                while(previousFee < fee) {
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
                    rewardsToDistribute: 0,
                    rewardPerToken: 0,
                    previousFee: previousFee,
                    nextFee: nextFee
                });
            }
        }
        // Give liquidity tokens to user
        _mint(msg.sender, token, amount, 0x00);
        // Save user info
        userInfo[msg.sender][token][fee].amount += amount;
        // Add to total available
        totalAvailable[token] += amount;

        // Take ERC20 tokens from user
        IERC20(token).transferFrom(msg.sender, address(this), amount);
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
        // Burn liquidity tokens
        _burn(msg.sender, token, amount);
        // Subtract from total available
        totalAvailable[token] -= amount;

        // Give ERC20 tokens to user
        IERC20(token).transfer(msg.sender, amount);
    }

    function distributeRewards(address token, uint feeLevel) external returns (uint){
        UserInfo storage user = userInfo[msg.sender][token][feeLevel];
        Pool storage pool = pools[token][feeLevel];
        // Check if user has rewards for token and fee level
        uint rewards = user.amount * (pool.rewardPerToken - user.rewardDebt);
        require(rewards > 0, "DeFlashLoan: No rewards to distribute");
        // Yes: transfer rewards to user
        IERC20(token).transfer(msg.sender, rewards);
        // Update user info
        user.rewardDebt = pool.rewardPerToken;
    }

    // ERC1155

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    // IERC3156FlashLender

        /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(
        address token
    ) external view returns (uint256) {
        return totalAvailable[token];
    }

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(
        address token,
        uint256 amount
    ) external view returns (uint256) {
        // TODO: calculate the amount of tokens to be charged for the loan
    }

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool) {
        // Check lowest fee amount
        // Is amount > lowest fee amount?
        // Yes: check next fee amount
        // Repeat until amount is less than summed amounts
        // Take flash loan at highest fee
        // Do stuff
        // Pay back flash loan + commission
        // Distribute commission

        // uint256 fee = _flashFee(token, amount);
        // // TODO: check if this is correct
        // IERC20(token).transfer(address(receiver), amount);
        // require(
        //     receiver.onFlashLoan(msg.sender, token, amount, fee, data) == CALLBACK_SUCCESS,
        //     "FlashMinter: Callback failed"
        // );
        // uint256 _allowance = allowance(address(receiver), address(this));
        // require(
        //     _allowance >= (amount + fee),
        //     "FlashMinter: Repay not approved"
        // );
        // _approve(address(receiver), address(this), _allowance - (amount + fee));
        return true;
    }

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._update(from, to, ids, values);
    }
}
