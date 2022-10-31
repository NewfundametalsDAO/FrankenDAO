// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { StakingBase } from "../bases/StakingBase.t.sol";

contract StakingCommunityVotingPowerTests is StakingBase {

    // ----
    // Multipliers
    // ----
    // multipliers set in constructor
    function testCommunityVP__MultipliersSetInCustructor() public {
        (uint64 votes, uint64 proposalsCreated, uint64 proposalsPassed)
            = staking.communityPowerMultipliers();
        assertEq(votes, 100);
        assertEq(proposalsCreated, 200);
        assertEq(proposalsPassed, 200);
    }

    // update votes multiplier
    function testCommunityVP__updateVotesMultiplier() public {
        vm.prank(address( executor ));
        staking.setVotesMultiplier(50);

        (uint64 votes, uint64 proposalsCreated, uint64 proposalsPassed)
            = staking.communityPowerMultipliers();

        assertEq(votes, 50);
    }
    // update proposalsCreated multiplier
    function testCommunityVP__UpdateProposalsCreatedMultiplier() public {
        vm.prank(address( executor ));
        staking.setProposalsCreatedMultiplier(50);

        (uint64 votes, uint64 proposalsCreated, uint64 proposalsPassed)
            = staking.communityPowerMultipliers();

        assertEq(proposalsCreated, 50);
    }
    // update proposalsPassed multiplier
    function testCommunityVP__updateProposalsPassedMultiplier() public {
        vm.prank(address( executor ));
        staking.setProposalsPassedMultiplier(50);

        (uint64 votes, uint64 proposalsCreated, uint64 proposalsPassed)
            = staking.communityPowerMultipliers();

        assertEq(proposalsPassed, 50);
    }

    // ----
    // Individual Community Voting Power
    // ----

    // delegating sets my community voting power to 0
    function testCommunityVP__DelegatingSetsCPToZero() public {
        address user = mockStakeSingle(1000);
        address delegate = mockStakeSingle(3215);

        vm.prank(user);
        staking.delegate(delegate);

        assertEq(staking.getCommunityVotingPower(user), 0);
    }
    // undelegating resets my community voting power
    function testCommunityVP__UndelegatingResetsCP() public {
        address user = mockStakeSingle(1000);
        address delegate = mockStakeSingle(3215);

        uint initialCommunityVP = staking.getCommunityVotingPower(user);

        vm.prank(user);
        staking.delegate(delegate);

        uint delegatedCommunityVP = staking.getCommunityVotingPower(user);

        assertEq(delegatedCommunityVP, 0);

        vm.prank(user);
        staking.delegate(user);

        uint undelegatedCommunityVP = staking.getCommunityVotingPower(user);

        assertEq(undelegatedCommunityVP, initialCommunityVP);
    }

    // ----
    // Total + Individual Community Voting Power
    // ----


    // ----
    // Total Community Voting Power
    // ----

}

