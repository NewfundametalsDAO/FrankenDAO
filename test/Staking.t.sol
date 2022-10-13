// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Staking.sol";

contract StakingTest is Test {
    Staking staking;

    function setUp() public {
        staking = new Staking(
            address(0),
            address(0),
            address(0),
            address(0),
            0,
            0,
            0,
            0,
            0
        );
    }

    function testEvilScores() public {
        assert(true);
    }


    // make sure transferFrom blocks all token transfers (safe with both sigs)
    // test evil bonus
}
