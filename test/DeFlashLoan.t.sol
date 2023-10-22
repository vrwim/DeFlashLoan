// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {DeFlashLoan} from "../src/DeFlashLoan.sol";

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC3156FlashBorrower.sol";

contract DeFlashLoanTest is Test {
    DeFlashLoan public myContract;
    DummyERC20 public dummyToken;
    DummyFlashLoanBorrower public dummyBorrower;

    uint constant public DIGITS_MULTIPLIER = 1e18;
    uint immutable public REWARD_FEE_DIVISOR = 1_000_000;

    // Test users
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public user3 = address(0x3);
    address public user4 = address(0x4);
    address public user5 = address(0x5);

    function setUp() public {
        myContract = new DeFlashLoan();
        dummyToken = new DummyERC20();
        dummyBorrower = new DummyFlashLoanBorrower();
    }

    function testFlashFee() public {
        testDeposit();
        assertEq(myContract.flashFee(address(dummyToken), 100 * DIGITS_MULTIPLIER), 100 * DIGITS_MULTIPLIER * 10_000 / REWARD_FEE_DIVISOR);
    }

    function testDeposit() public {
        dummyToken.mint(address(this), 100 * DIGITS_MULTIPLIER);
        dummyToken.approve(address(myContract), 100 * DIGITS_MULTIPLIER);

        myContract.deposit(address(dummyToken), 100 * DIGITS_MULTIPLIER, 10_000);

        assertEq(myContract.totalAvailable(address(dummyToken)), 100 * DIGITS_MULTIPLIER);

        (uint thisFeeAmount, uint rewardPerToken, uint previousFee, uint nextFee) = myContract.pools(address(dummyToken), 10_000);
        assertEq(thisFeeAmount, 100 * DIGITS_MULTIPLIER);
        assertEq(rewardPerToken, 0);
        assertEq(previousFee, 0);
        assertEq(nextFee, 0);
    }

    function testDeposit2() public {
        dummyToken.mint(address(this), 200 * DIGITS_MULTIPLIER);
        dummyToken.approve(address(myContract), 200 * DIGITS_MULTIPLIER);

        myContract.deposit(address(dummyToken), 100 * DIGITS_MULTIPLIER, 10);
        myContract.deposit(address(dummyToken), 100 * DIGITS_MULTIPLIER, 20);
        assertEq(myContract.totalAvailable(address(dummyToken)), 200 * DIGITS_MULTIPLIER);
    }

    function testPartialDeposit() public {
        dummyToken.mint(address(this), 150 * DIGITS_MULTIPLIER);
        dummyToken.approve(address(myContract), 150 * DIGITS_MULTIPLIER);

        myContract.deposit(address(dummyToken), 100 * DIGITS_MULTIPLIER, 10);
        myContract.deposit(address(dummyToken), 50 * DIGITS_MULTIPLIER, 10);
        assertEq(myContract.totalAvailable(address(dummyToken)), 150 * DIGITS_MULTIPLIER);
    }

    function testWithdrawAll() public {
        dummyToken.mint(address(this), 100 * DIGITS_MULTIPLIER);
        dummyToken.approve(address(myContract), 100 * DIGITS_MULTIPLIER);

        myContract.deposit(address(dummyToken), 100 * DIGITS_MULTIPLIER, 10);
        myContract.withdraw(address(dummyToken), 100 * DIGITS_MULTIPLIER, 10);
        assertEq(myContract.totalAvailable(address(dummyToken)), 0);
        (uint amount, uint rewardDebt) = myContract.userInfo(address(this), address(dummyToken), 10);
        assertEq(amount, 0);
        assertEq(rewardDebt, 0);
    }

    function testPartialWithdraw() public {
        dummyToken.mint(address(this), 150 * DIGITS_MULTIPLIER);
        dummyToken.approve(address(myContract), 150 * DIGITS_MULTIPLIER);

        myContract.deposit(address(dummyToken), 100 * DIGITS_MULTIPLIER, 10);
        myContract.withdraw(address(dummyToken), 50 * DIGITS_MULTIPLIER, 10);
        assertEq(myContract.totalAvailable(address(dummyToken)), 50 * DIGITS_MULTIPLIER);
    }

    function testFlashLoan() public {
        uint user1Deposit = 100 * DIGITS_MULTIPLIER;
        uint user2Deposit = 100 * DIGITS_MULTIPLIER;
        uint loanValue = 200 * DIGITS_MULTIPLIER;
        uint loanFee = 10_000;
        uint fee = loanValue * loanFee / REWARD_FEE_DIVISOR;

        dummyToken.mint(user1, user1Deposit);
        dummyToken.mint(user2, user2Deposit);

        // First user deposits at loanFee / 2
        vm.startPrank(user1);
        dummyToken.approve(address(myContract), user1Deposit);
        myContract.deposit(address(dummyToken), user1Deposit, loanFee / 2);
        vm.stopPrank();

        // Second user deposits at loanFee
        vm.startPrank(user2);
        dummyToken.approve(address(myContract), user2Deposit);
        myContract.deposit(address(dummyToken), user2Deposit, loanFee);
        vm.stopPrank();

        // Ensure the deposit worked
        assertEq(myContract.lowestFeeAmount(address(dummyToken)), loanFee / 2);
        assertEq(myContract.flashFee(address(dummyToken), loanValue), fee);

        // Take the flash loan
        myContract.flashLoan(dummyBorrower, address(dummyToken), loanValue, bytes(""));

        // Ensure the total available increased
        assertEq(myContract.totalAvailable(address(dummyToken)), user1Deposit + user2Deposit + fee);

        // Ensure each pool got updated
        (uint thisFeeAmount, uint rewardPerToken, uint previousFee, uint nextFee) = myContract.pools(address(dummyToken), loanFee / 2);
        assertEq(thisFeeAmount, user1Deposit + user1Deposit * loanFee / REWARD_FEE_DIVISOR, "thisFeeAmount");
        assertEq(rewardPerToken, fee * REWARD_FEE_DIVISOR / (user1Deposit + user2Deposit), "rewardPerToken");
        assertEq(previousFee, 0, "previousFee");
        assertEq(nextFee, loanFee, "nextFee");

        (uint thisFeeAmount2, uint rewardPerToken2, uint previousFee2, uint nextFee2) = myContract.pools(address(dummyToken), loanFee);
        assertEq(thisFeeAmount2, user2Deposit + user2Deposit * loanFee / REWARD_FEE_DIVISOR, "thisFeeAmount2");
        assertEq(rewardPerToken2, fee * REWARD_FEE_DIVISOR / (user1Deposit + user2Deposit), "rewardPerToken2");
        assertEq(previousFee2, loanFee / 2, "previousFee2");
        assertEq(nextFee2, 0, "nextFee2");

        vm.prank(user1);
        assertEq(myContract.distributeRewards(address(dummyToken), loanFee / 2), fee / 2, "distributeRewards");
    }
    
    // TODO: need more tests!
}

/// @dev A mock ERC20 token that allows anyone to mint tokens
contract DummyERC20 is ERC20 {
    constructor() ERC20("Dummy", "DUM") { }
    
    // Allow anyone to mint tokens
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

/// @dev A mock flash loan borrower
contract DummyFlashLoanBorrower is IERC3156FlashBorrower {
    function onFlashLoan(address, address token, uint256 amount, uint256 fee, bytes calldata) external returns (bytes32) {
        DummyERC20(token).mint(address(this), fee);
        DummyERC20(token).approve(msg.sender, amount + fee);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}