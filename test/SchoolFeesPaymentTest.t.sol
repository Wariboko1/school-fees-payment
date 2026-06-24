// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {SchoolFeesPayment} from "../src/SchoolFeesPayment.sol";

contract SchoolFeesPaymentTest is Test {           // ← Recommended: Rename test contract
    SchoolFeesPayment public schoolFeesPayment; 
       // ← Added semicolon + public (good practice)

       receive() external payable {}

    function setUp() external {
        schoolFeesPayment = new SchoolFeesPayment();
    }

    function testAdminCanOpenPortal() public {
        // Act
        schoolFeesPayment.setPortalStatus(true);

        // Assert
        assertEq(schoolFeesPayment.isPaymentPortalOpen(), true);
    }

    function testNonAdminCannotOpenPortal() public {
        address stranger = makeAddr("stranger");
        vm.prank(stranger);
        vm.expectRevert("Only school admin can perform this action");
        schoolFeesPayment.setPortalStatus(true);
    }

    function testRegisterStudent() public {
    string memory matric = "CSC/2021/001";
    string memory faculty = "Science";
    uint256 level = 300;
    address wallet = makeAddr("student1");

    schoolFeesPayment.registerStudent(matric, faculty, level, wallet);

    (
        string memory storedMatric,
        string memory storedFaculty,
        uint256 storedLevel,
        address storedWallet,
        bool hasPaid,
        uint256 amountPaid,
        uint256 paymentTime
    ) = schoolFeesPayment.students(matric);

    assertEq(storedMatric, matric);
    assertEq(storedFaculty, faculty);
    assertEq(storedLevel, level);
    assertEq(storedWallet, wallet);
    assertEq(hasPaid, false);
    assertEq(amountPaid, 0);      // ← add this
    assertEq(paymentTime, 0);     // ← and this
}

function testCannotRegisterSameStudentTwice() public {
    string memory matric = "CSC/2021/001";

    schoolFeesPayment.registerStudent(matric, "Science", 300, makeAddr("student1"));

    vm.expectRevert("Students already exist");
    schoolFeesPayment.registerStudent(matric, "Science", 300, makeAddr("student1")); 
}

function testStudentCanPayFees() public {
    string memory matric = "CSC/2021/001";
    address wallet = makeAddr("student1");
    uint256 feeAmount = 1 ether;
    uint256 deadline = block.timestamp + 7 days;
    schoolFeesPayment.registerStudent(matric, "Science", 300, wallet);
    schoolFeesPayment.setFees("Science", 300, feeAmount);
    schoolFeesPayment.setPaymentDeadline(deadline);
    schoolFeesPayment.setExtraPenalty(0.1 ether);
    schoolFeesPayment.setPortalStatus(true);

    vm.deal(wallet, 2 ether);
    vm.prank(wallet);

    schoolFeesPayment.paySchoolFees{value: feeAmount}(matric);
    (bool hasPaid, uint256 amountPaid, ) = schoolFeesPayment.checkPaymentStatus(matric);

    assertEq(hasPaid, true);
    assertEq(amountPaid, feeAmount);
}

function testLatePaymentRequiresPenalty() public {
    string memory matric = "CSC/2021/001";
    address wallet = makeAddr("student1");
    uint256 feeAmount = 1 ether;
    uint256 penalty = 0.1 ether;
    uint256 deadline = block.timestamp + 7 days;

    schoolFeesPayment.registerStudent(matric, "Science", 300, wallet);
    schoolFeesPayment.setFees("Science", 300, feeAmount);
    schoolFeesPayment.setPaymentDeadline(deadline);
    schoolFeesPayment.setExtraPenalty(penalty);
    schoolFeesPayment.setPortalStatus(true);

    vm.deal(wallet, 5 ether);
    vm.warp(deadline + 1 days);
    vm.prank(wallet);

     schoolFeesPayment.paySchoolFees{value: feeAmount + penalty}(matric);
    (bool hasPaid, uint256 amountPaid, ) = schoolFeesPayment.checkPaymentStatus(matric);

    assertEq(hasPaid, true);
    assertEq(amountPaid, feeAmount + penalty);
}

function testAdminCanWithdraw() public {
    string memory matric = "CSC/2021/001";
    address student = makeAddr("student1");
    uint256 feeAmount = 1 ether;

    // Setup
    schoolFeesPayment.registerStudent(matric, "Science", 300, student);
    schoolFeesPayment.setFees("Science", 300, feeAmount);
    schoolFeesPayment.setPaymentDeadline(block.timestamp + 7 days);  // ← add this
    schoolFeesPayment.setExtraPenalty(0.1 ether);                    // ← add this
    schoolFeesPayment.setPortalStatus(true);

    vm.deal(student, 2 ether);
    vm.prank(student);
    schoolFeesPayment.paySchoolFees{value: feeAmount}(matric);

    // Snapshot balances before
    uint256 adminBalanceBefore = address(this).balance;              // ← use address(this)
    uint256 contractBalanceBefore = address(schoolFeesPayment).balance;

    // Act — no vm.prank needed, test contract IS the admin
    schoolFeesPayment.withdraw();                                     // ← remove vm.prank

    // Assert
    assertEq(contractBalanceBefore, feeAmount);
    assertEq(address(schoolFeesPayment).balance, 0);
    assertEq(address(this).balance, adminBalanceBefore + feeAmount); // ← use address(this)
}

function  testNonAdminCannotWithdraw() public {
        address stranger = makeAddr("stranger");
        vm.prank(stranger);
        vm.expectRevert("Only school admin can perform this action");
        schoolFeesPayment.withdraw();
}

function testWithdrawRevertsIfNoBalance() public {
    vm.expectRevert("No funds to withdraw"); // ← match your contract
    schoolFeesPayment.withdraw();
}

function testPaymentRevertsIfPortalClosed() public {
    string memory matric = "CSC/2021/001";
    schoolFeesPayment.registerStudent(matric, "Science", 300, makeAddr("Student1"));

    vm.expectRevert("Payment portal is currently closed");
    schoolFeesPayment.paySchoolFees{value: 1 ether}(matric);
}

function testPaymentRevertsIfWrongAmount() public {
    string memory matric = "CSC/2021/001";
    address wallet = makeAddr("student1");

    schoolFeesPayment.registerStudent(matric, "Science", 300, wallet);
    schoolFeesPayment.setFees("Science", 300, 1 ether);
    schoolFeesPayment.setPaymentDeadline(block.timestamp + 7 days);
    schoolFeesPayment.setExtraPenalty(0.1 ether);
    schoolFeesPayment.setPortalStatus(true);

    vm.deal(wallet, 2 ether);
    vm.prank(wallet);
    vm.expectRevert("Incorrect payment amount");
    schoolFeesPayment.paySchoolFees{value: 0.5 ether}(matric);
}

function testPaymentRevertsIfAlreadyPaid() public {
    string memory matric = "CSC/2021/001";
    address wallet = makeAddr("student1");

    // full setup first
    schoolFeesPayment.registerStudent(matric, "Science", 300, wallet);
    schoolFeesPayment.setFees("Science", 300, 1 ether);
    schoolFeesPayment.setPaymentDeadline(block.timestamp + 7 days);
    schoolFeesPayment.setExtraPenalty(0.1 ether);
    schoolFeesPayment.setPortalStatus(true);

    // first payment — succeeds
    vm.deal(wallet, 5 ether);
    vm.prank(wallet);
    schoolFeesPayment.paySchoolFees{value: 1 ether}(matric);

    // second payment — should revert
    vm.prank(wallet);
    vm.expectRevert("Students has already paid");
    schoolFeesPayment.paySchoolFees{value: 1 ether}(matric);
}

}