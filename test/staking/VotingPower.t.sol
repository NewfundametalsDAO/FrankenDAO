// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { StakingBase } from "../bases/StakingBase.t.sol";
import { IERC721 } from "../../src/interfaces/IERC721.sol";

contract VotingPowerTests is StakingBase {
    uint256 FAKE_ID = 12;

    // Test that staking, delegating, and undelegating all adjust voting power.
    function testStakingVP__UndelegatingUpdatesVotingPower() public {
        address staker = frankenpunks.ownerOf(FAKE_ID);
        assert(staking.getVotes(staker) == 0);

        address owner = mockStakeSingle(FAKE_ID);
        assert(owner == staker);

        uint256 evilBonus = staking.evilBonus(FAKE_ID);

        assert(staking.getVotes(staker) == 20 + evilBonus);

        vm.prank(staker);
        staking.delegate(address(1));

        assert(staking.getVotes(staker) == 0);

        vm.prank(staker);
        staking.delegate(address(0));

        assert(staking.getVotes(staker) == 20 + evilBonus);
    }

    // Test that unstaking reduces voting power.
    function testStakingVP__UnstakingReducesVotingPower() public {
        address staker = frankenpunks.ownerOf(FAKE_ID);

        // default to 0
        assert(staking.getVotes(staker) == 0);

        address owner = mockStakeSingle(FAKE_ID, block.timestamp + 1 days);
        assert(owner == staker);

        uint256 evilBonus = staking.evilBonus(FAKE_ID);

        emit log_named_uint("evilBonus", evilBonus + 20);
        emit log_named_uint("getVotes", staking.getVotes(staker));

        assert(staking.getVotes(staker) == 20 + evilBonus);

        vm.warp(block.timestamp + 2 days);
        mockUnstakeSingle(FAKE_ID);

        emit log_named_uint("getVotes", staking.getVotes(staker));
        assert(staking.getVotes(staker) == 0);
    }
}
