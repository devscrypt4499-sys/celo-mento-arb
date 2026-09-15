// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Arbitrage.sol";

contract ArbitrageTest is Test {
    Arbitrage public arb;

    function setUp() public {
        arb = new Arbitrage();
    }

    function test_ownerIsSet() public {
        assertEq(arb.owner(), address(this));
    }

    function test_minProfit() public {
        assertEq(arb.minProfit(), 4e6);
    }

    function check_onlyOwner(address caller) public {
        vm.assume(caller != arb.owner());

        vm.prank(caller);
        vm.expectRevert("Not owner");
        arb.requestFlashLoan(1e6);
    }
}
