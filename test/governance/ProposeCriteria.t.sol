// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { GovernanceBase } from "../bases/GovernanceBase.t.sol";
import { IGovernance } from "../../src/interfaces/IGovernance.sol";

contract ProposeCriteriaTests is GovernanceBase {
    // Test that a proposal can be created by the proposer
    function testGovPropose__CanCreatePendingProposal() public {
        uint proposalId = _createProposal();
        assert(gov.state(proposalId) == IGovernance.ProposalState.Pending);
    }

    // Test that a stranger (someone with no votes) cannot create a proposal.
    function testGovPropose__CannotCreateProposalWithInsufficientVotes() public {
        (
            address[] memory targets, 
            uint[] memory values, 
            string[] memory sigs, 
            bytes[] memory calldatas
        ) = _generateFakeProposalData();

        vm.prank(stranger);
        vm.expectRevert(NotEligible.selector);
        gov.propose(targets, values, sigs, calldatas, "test");
    }

    // Test that someone with an Active Proposal cannot create another one.
    function testGovPropose__CannotCreateProposalIfAlreadyHaveActive() public {
        uint proposalId = _createProposal();
        vm.expectRevert(NotEligible.selector);
        uint proposalId2 = _createProposal();
    }

    // Test that someone can create a new proposal after their last one was cancelled.
    function testGovPropose__CanCreateProposalAfterCancel() public {
        uint proposalId = _createProposal();
        vm.prank(proposer);
        gov.cancel(proposalId);
        uint proposalId2 = _createProposal();
    }

    // Test that someone can create a new proposal after their last one was vetoed.
    function testGovPropose__CanCreateProposalAfterVeto() public {
        uint proposalId = _createProposal();
        vm.prank(FOUNDER_MULTISIG);
        gov.veto(proposalId);
        uint proposalId2 = _createProposal();
    }

    // Test that someone can create a new proposal after their last one was queued.
    function testGovPropose__CanCreateProposalAfterExecute() public {
        uint proposalId = _createSuccessfulProposal();
        gov.queue(proposalId);
        uint proposalId2 = _createProposal();
    }
}


