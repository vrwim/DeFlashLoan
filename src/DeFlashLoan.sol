// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

contract DeFlashLoan {
    struct Pool {
        uint thisFeeAmount;

        // This becomes a doubly linked list
        uint previousFee;
        uint nextFee;

        uint commissionToDistribute;
    }

    // Change this to the ERC1155 token
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    // Token address => lowest fee amount (start of doubly linked list)
    mapping(address => uint) public lowestFeeAmount;

    // Token address => fee amount => fee pool
    mapping(address => mapping(uint => Pool)) public pools;

    // TODO: refactor to ERC20Receiver or something
    function deposit(address token, uint256 amount, uint fee) external {
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

    // TODO: is there a flash loan ERC?
    function takeFlashLoan(address token, uint amount) external {
        // Check lowest fee amount
        // Is amount > lowest fee amount?
        // Yes: check next fee amount
        // Repeat until amount is less than summed amounts
        // Take flash loan at highest fee
        // Do stuff
        // Pay back flash loan + commission
        // Distribute commission
    }
}
