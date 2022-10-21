pragma solidity ^0.8.13;

import { GovernanceBase } from "./GovernanceBase.t.sol";

contract ProposalThresholdTests is GovernanceBase {
    // Test that the founder multisig can change the proposal threshold.
    function testGovThreshold__FounderCanChangeProposalThresholdButErrorsOutsideRange(uint newThreshold) public {
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
    function testGovThreshold__StrangerCannotChangeThreshold() public {
        uint newThreshold = 100;
        vm.prank(stranger);
        vm.expectRevert(Unauthorized.selector);
        gov.setProposalThresholdBPS(newThreshold);
    }

    // Test that the founder multisig can change the quorum vote threshold.
    function testGovThreshold__FounderCanChangeQuorumThresholdButErrorsOutsideRange(uint newThreshold) public {
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
    function testGovThreshold__StrangerCannotChangeQuorumThreshold() public {
        uint newThreshold = 1000;
        vm.prank(stranger);
        vm.expectRevert(Unauthorized.selector);
        gov.setQuorumVotesBPS(newThreshold);
    }
}
