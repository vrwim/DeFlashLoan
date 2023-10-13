// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {DeFlashLoan} from "../src/DeFlashLoan.sol";

import "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract DeFlashLoanTest is Test {
    DeFlashLoan public myContract;
    DummyERC20 public dummyToken;

    function setUp() public {
        myContract = new DeFlashLoan();
        dummyToken = new DummyERC20();
    }

    function testDeposit() public {
        myContract.deposit(address(dummyToken), 100, 10);
        assertEq(myContract.totalAvailable(address(dummyToken)), 100);
    }

    function testDeposit() public {
        myContract.deposit(address(dummyToken), 100, 10);
        myContract.deposit(address(dummyToken), 100, 20);
        assertEq(myContract.totalAvailable(address(dummyToken)), 200);
    }

    function testPartialDeposit() public {
        myContract.deposit(address(dummyToken), 100, 10);
        myContract.deposit(address(dummyToken), 50, 10);
        assertEq(myContract.totalAvailable(address(dummyToken)), 150);
    }

    function testWithdraw() public {
        myContract.deposit(address(dummyToken), 100, 10);
        myContract.withdraw(address(dummyToken), 100, 10);
        assertEq(myContract.totalAvailable(address(dummyToken)), 0);
    }

    function testPartialWithdraw() public {
        myContract.deposit(address(dummyToken), 100, 10);
        myContract.withdraw(address(dummyToken), 50, 10);
        assertEq(myContract.totalAvailable(address(dummyToken)), 50);
    }
}

/// @dev A mock ERC20 token that always succeeds transfers
contract DummyERC20 is ERC20 {
    constructor() ERC20("Dummy", "DUM") { }

    // Fake transfer method that always succeeds
    function transfer(address, uint) public override returns (bool) {
        return true;
    }
    function transferFrom(address, address, uint) public override returns (bool) {
        return true;
    }
}