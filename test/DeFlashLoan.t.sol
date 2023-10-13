// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {DeFlashLoan} from "../src/DeFlashLoan.sol";

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol";

contract DeFlashLoanTest is Test, IERC1155Receiver {
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

    function testDeposit2() public {
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

    // Functions that need to be implemented for ERC1155Receiver
        function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        return 0xbc197c81;
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return true;
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