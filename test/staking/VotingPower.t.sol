// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { StakingBase } from "../bases/StakingBase.t.sol";

contract VotingPowerTests is StakingBase {

    // Test that staking, delegating, and undelegating all adjust voting power.
    function testStakingVP__DelegatingAndUndelegatingUpdateVotingPower() public {
        address staker = frankenpunks.ownerOf(PUNK_ID);
        assert(staking.getVotes(staker) == 0);

        address owner = mockStakeSingle(PUNK_ID);
        assert(owner == staker);

        uint256 evilBonus = staking.evilBonus(PUNK_ID);

        assert(staking.getVotes(staker) == staking.BASE_VOTES() + evilBonus);

        vm.prank(staker);
        staking.delegate(address(1));

        assert(staking.getVotes(staker) == 0);

        vm.prank(staker);
        staking.delegate(address(0));

        assert(staking.getVotes(staker) == staking.BASE_VOTES() + evilBonus);
    }

    // Test that unstaking reduces voting power.
    function testStakingVP__StakingAndUnstakingUpdateVotingPower() public {
        address staker = frankenpunks.ownerOf(PUNK_ID);
        assert(staking.getVotes(staker) == 0);

        address owner = mockStakeSingle(PUNK_ID, 0);
        assert(owner == staker);

        uint256 evilBonus = staking.evilBonus(PUNK_ID);

        assert(staking.getVotes(staker) == staking.BASE_VOTES() + evilBonus);

        vm.warp(block.timestamp + 28 days);
        mockUnstakeSingle(PUNK_ID);

        assert(staking.getVotes(staker) == 0);
    }
}