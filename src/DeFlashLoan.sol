// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./IERC3156FlashLender.sol";

contract DeFlashLoan is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply, IERC3156FlashLender {
    struct Pool {
        /// @dev The amount of tokens in the pool at this fee level
        uint thisFeeAmount;
        /// @dev The amount of rewards in the pool that haven't been distributed at this fee level
        uint rewardsToDistribute;

        // This becomes a doubly linked list
        uint previousFee;
        uint nextFee;
    }

    struct UserInfo {
        uint amount;
        uint rewardDebt;
    }

    // Token address => lowest fee amount (start of doubly linked list)
    mapping(address => uint) public lowestFeeAmount;

    // Token address => total available tokens (to cache this commonly requested value)
    mapping(address => uint) public totalAvailable;

    // Token address => fee amount => fee pool
    mapping(address => mapping(uint => Pool)) public pools;

    // User address => token address => fee level => user info
    mapping(address => mapping(address => mapping(uint => UserInfo))) public userInfo;

    constructor(address initialOwner) ERC1155("") Ownable(initialOwner) { }

    // TODO: refactor to ERC20Receiver or something
    function deposit(address token, uint amount, uint fee) external {
        // Does fee exist?
        // Yes: add amount to mapping
        // No: Create mapping, change previousFee and nextFee of previous and next fee
        // Give liquidity tokens to user
        // Save user info
    }

    function withdraw(address token, uint amount, uint fee) external {
        // Subtract amount from mapping
        // Is thisFeeAmount 0?
        // Yes: Delete mapping, change previousFee and nextFee of previous and next fee
    }

    function distributeRewards(address token, uint feeLevel) external {
        // Check if user has rewards
        // Yes: transfer rewards to user
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

        uint256 fee = _flashFee(token, amount);
        // TODO: check if this is correct
        IERC20(token).transfer(address(receiver), amount);
        require(
            receiver.onFlashLoan(msg.sender, token, amount, fee, data) == CALLBACK_SUCCESS,
            "FlashMinter: Callback failed"
        );
        uint256 _allowance = allowance(address(receiver), address(this));
        require(
            _allowance >= (amount + fee),
            "FlashMinter: Repay not approved"
        );
        _approve(address(receiver), address(this), _allowance - (amount + fee));
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
