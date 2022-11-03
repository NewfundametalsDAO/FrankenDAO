// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { GovernanceBase } from "../bases/GovernanceBase.t.sol";

contract GovParamsTests is GovernanceBase {
    
    // Test that all starting params have been set correctly.
    function testGovParams__TestAllCorrectStartingParams() public view {
        assert(gov.proposalThresholdBPS() == 500);
        assert(gov.quorumVotesBPS() == 2000);
        assert(gov.votingDelay() == 1 days);
        assert(gov.votingPeriod() == 7 days);
    }

    // Test that the founder multisig can change the proposal threshold.
    function testGovParams__FounderCanChangeProposalThresholdButErrorsOutsideRange(uint newThreshold) public {
        vm.startPrank(FOUNDER_MULTISIG);
        if (newThreshold < gov.MIN_PROPOSAL_THRESHOLD_BPS() || newThreshold > gov.MAX_PROPOSAL_THRESHOLD_BPS()) {
            vm.expectRevert(ParameterOutOfBounds.selector);
            gov.setProposalThresholdBPS(newThreshold);
        } else {
            gov.setProposalThresholdBPS(newThreshold);
            assert(gov.proposalThresholdBPS() == newThreshold);
        }
        vm.stopPrank();
    }

    // Test that a stranger cannot change the proposal threshold.
    function testGovParams__StrangerCannotChangeThreshold() public {
        uint newThreshold = 100;
        vm.prank(stranger);
        vm.expectRevert(NotAuthorized.selector);
        gov.setProposalThresholdBPS(newThreshold);
    }

    // Test that the founder multisig can change the quorum vote threshold.
    function testGovParams__FounderCanChangeQuorumThresholdButErrorsOutsideRange(uint newThreshold) public {
        vm.startPrank(FOUNDER_MULTISIG);
        if (newThreshold < gov.MIN_QUORUM_VOTES_BPS() || newThreshold > gov.MAX_QUORUM_VOTES_BPS()) {
            vm.expectRevert(ParameterOutOfBounds.selector);
            gov.setQuorumVotesBPS(newThreshold);
        } else {
            gov.setQuorumVotesBPS(newThreshold);
            assert(gov.quorumVotesBPS() == newThreshold);
        }
        vm.stopPrank();
    }

    // Test that a stranger cannot change the quorum vote threshold.
    function testGovParams__StrangerCannotChangeQuorumThreshold() public {
        uint newThreshold = 1000;
        vm.prank(stranger);
        vm.expectRevert(NotAuthorized.selector);
        gov.setQuorumVotesBPS(newThreshold);
    }

    // Test that the executor can change the voting delay.
    function testGovParams__ExecutorCanChangeVotingDelayButErrorsOutsideRange(uint newDelay) public {
        vm.startPrank(address(executor));
        if (newDelay < gov.MIN_VOTING_DELAY() || newDelay > gov.MAX_VOTING_DELAY()) {
            vm.expectRevert(ParameterOutOfBounds.selector);
            gov.setVotingDelay(newDelay);
        } else {
            gov.setVotingDelay(newDelay);
            assert(gov.votingDelay() == newDelay);
        }
        vm.stopPrank();
    }

    // Test that a stranger cannot set the voting delay.
    function testGovParams__StrangerCannotChangeVotingDelay() public {
        uint newDelay = 1000;
        vm.prank(stranger);
        vm.expectRevert(NotAuthorized.selector);
        gov.setVotingDelay(newDelay);
    }

    // Test that the executor can change the voting period.
    function testGovParams__ExecutorCanChangeVotingPeriodButErrorsOutsideRange(uint newPeriod) public {
        vm.startPrank(address(executor));
        if (newPeriod < gov.MIN_VOTING_PERIOD() || newPeriod > gov.MAX_VOTING_PERIOD()) {
            vm.expectRevert(ParameterOutOfBounds.selector);
            gov.setVotingPeriod(newPeriod);
        } else {
            gov.setVotingPeriod(newPeriod);
            assert(gov.votingPeriod() == newPeriod);
        }
        vm.stopPrank();
    }

    // Test that a stranger cannot set the voting period.
    function testGovParams__StrangerCannotChangeVotingPeriod() public {
        uint newPeriod = 1000;
        vm.prank(stranger);
        vm.expectRevert(NotAuthorized.selector);
        gov.setVotingPeriod(newPeriod);
    }

    // Test that bpsToUint function works as expected.
    function testGovParams__bpstoUintSetsProposalParamsCorrectly() public {
        uint proposalId = _createProposal();
        (,, uint qThreshold) = gov.getProposalData(proposalId);

        uint totalVotes = staking.getTotalVotingPower();
        assert(qThreshold == 2000 * totalVotes / 10000);
    }
}
