// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DeployFaucet} from "../script/DeployFaucet.s.sol";
import {MyToken} from "../src/MyToken.sol";
import {Faucet} from "../src/Faucet.sol";

contract FaucetTest is Test {
    MyToken token;
    Faucet faucet;
    address USER = makeAddr("user");

    function setUp() public {
        DeployFaucet deployer = new DeployFaucet();
        (token, faucet) = deployer.run();  // ← added this line
        vm.warp(1 days + 1);
    }

    // Faucet balance test
    function test_FaucetIsFunded() public view {
        uint256 balance = faucet.faucetBalance();
        assertEq(balance, 10_000 * 10 ** 18);
    }

    // Request token tests
    function test_UserCanClaimToken() public {
        vm.prank(USER);
        faucet.requestToken();  // ← fixed

        uint256 userBalance = token.balanceOf(USER);
        assertEq(userBalance, 100 * 10 ** 18);  // ← added this assertion

        uint256 faucetBalance = faucet.faucetBalance();
        assertEq(faucetBalance, 9_900 * 10 ** 18);
    }

    function test_UserCanNotClaimTwiceIn24Hours() public {
        vm.prank(USER);
        faucet.requestToken();  // ← fixed

        vm.prank(USER);
        vm.expectRevert("Come back in 24 hours");
        faucet.requestToken();  // ← fixed
    }

    function test_UserCanClaimAgainAfter24Hours() public {
        vm.prank(USER);
        faucet.requestToken();  // ← fixed

        vm.warp(block.timestamp + 1 days);

        vm.prank(USER);
        faucet.requestToken();  // ← fixed

        uint256 userBalance = token.balanceOf(USER);
        assertEq(userBalance, 200 * 10 ** 18);
    }

    // Owner tests
    function test_OwnerCanWithdraw() public {
        address owner = faucet.owner();

        uint256 ownerBalanceBefore = token.balanceOf(owner);
        uint256 faucetBalanceBefore = faucet.faucetBalance();

        vm.prank(owner);
        faucet.withdraw();

        assertEq(faucet.faucetBalance(), 0);
        assertEq(token.balanceOf(owner), ownerBalanceBefore + faucetBalanceBefore);
    }

    function test_NonOwnerCanNotWithdraw() public {
        vm.prank(USER);
        vm.expectRevert();
        faucet.withdraw();
    }

    function test_OwnerCanSetDripAmount() public {
        address owner = faucet.owner();
        uint256 newAmount = 200 * 10 ** 18;

        vm.prank(owner);

        faucet.setDripAmount(newAmount);
        assertEq(faucet.dripAmount(), newAmount);
    }

    function test_NonOwnerCanNotSetDripAmount() public {
        vm.prank(USER);
        vm.expectRevert();

        faucet.setDripAmount(200 * 10 ** 18);
    }

    function test_RevertWhenFaucetIsEmpty() public {
        address owner = faucet.owner();

        vm.prank(owner);
        faucet.withdraw();

        assertEq(faucet.faucetBalance(), 0);

        vm.prank(USER);
        vm.expectRevert("Faucet is empty");
        faucet.requestToken();
    }

    function test_TimeUntilIsClaim() public {
        vm.prank(USER);
        faucet.requestToken();

        uint256 timeleft = faucet.timeUntilNextClaim(USER);

        assertLe(timeleft, 1 days);
        assertGt(timeleft, 0);
    }

    function test_TimeUntilNextClaimReturnsZeroWhenReady() public {
        vm.prank(USER);
        faucet.requestToken();

        vm.warp(block.timestamp + 1 days);

        uint256 timeleft = faucet.timeUntilNextClaim(USER);

        assertEq(timeleft, 0);
    }
}