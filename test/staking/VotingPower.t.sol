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

        assert(staking.getVotes(staker) == staking.baseVotes() + evilBonus);

        vm.prank(staker);
        staking.delegate(address(1));

        assert(staking.getVotes(staker) == 0);

        vm.prank(staker);
        staking.delegate(address(0));

        assert(staking.getVotes(staker) == staking.baseVotes() + evilBonus);
    }

    // Test that unstaking reduces voting power.
    function testStakingVP__StakingAndUnstakingUpdateVotingPower() public {
        address staker = frankenpunks.ownerOf(PUNK_ID);
        assert(staking.getVotes(staker) == 0);

        address owner = mockStakeSingle(PUNK_ID, 0);
        assert(owner == staker);

        uint256 evilBonus = staking.evilBonus(PUNK_ID);

        assert(staking.getVotes(staker) == staking.baseVotes() + evilBonus);

        vm.warp(block.timestamp + 28 days);
        mockUnstakeSingle(PUNK_ID);

        assert(staking.getVotes(staker) == 0);
    }

    // @todo write test fuzzing time locked up
    // // Test that staking for a give amount of time hits voting power it should.
    // function testStakingVP__StakingForTimeUpdatesVotingPower() public {
    //     address staker = frankenpunks.ownerOf(PUNK_ID);
    //     assert(staking.getVotes(staker) == 0);

    //     address owner = mockStakeSingle(PUNK_ID);
    //     assert(owner == staker);

    //     uint256 evilBonus = staking.evilBonus(PUNK_ID);

    //     assert(staking.getVotes(staker) == staking.baseVotes() + evilBonus);

    //     vm.prank(staker);
    //     staking.stakeFor(PUNK_ID, 1 days);

    //     assert(staking.getVotes(staker) == staking.baseVotes() + evilBonus);

    //     vm.prank(staker);
    //     staking.stakeFor(PUNK_ID, 2 days);

    //     assert(staking.getVotes(staker) == 40 + evilBonus);

    //     vm.prank(staker);
    //     staking.stakeFor(PUNK_ID, 3 days);

    //     assert(staking.getVotes(staker) == 60 + evilBonus);

    //     vm.prank(staker);
    //     staking.stakeFor(PUNK_ID, 4 days);

    //     assert(staking.getVotes(staker) == 80 + evilBonus);

    //     vm.prank(staker);
    //     staking.stakeFor(PUNK_ID, 5 days);

    //     assert(staking.getVotes(staker) == 100 + evilBonus);
    // }
}
