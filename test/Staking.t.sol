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

    // Test only exists for sample data, where all evens are evil. Redo with JSON call once we have final.
    function testEvilScores(uint tokenId) public {
        vm.assume(tokenId < 20000);
        if (tokenId % 2 == 1 || tokenId >= 10000) {
            assert(staking.evilBonus(tokenId) == 0);
        } else {
            assert(staking.evilBonus(tokenId) == 10);
        }
        
    }

    // make sure transferFrom blocks all token transfers (safe with both sigs)
    // test evil bonus
}
