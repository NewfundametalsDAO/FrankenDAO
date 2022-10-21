pragma solidity ^0.8.13;

import { GovernanceBase } from "./GovernanceBase.t.sol";
import { IGovernance } from "../../src/interfaces/IGovernance.sol";

contract ProposeTest is GovernanceBase {
    // Test that a proposal can be created by the proposer
    function testGovPropose__CanCreatePendingProposal() public {
        (address[] memory targets, uint[] memory values, string[] memory sigs, bytes[] memory calldatas) = _generateFakeProposalData();

        vm.prank(proposer);
        uint proposalId = gov.propose(targets, values, sigs, calldatas, "test");
        IGovernance.ProposalState proposalState = gov.state(proposalId);
        assert(proposalState == IGovernance.ProposalState.Pending);
    }

    // Test that a stranger (someone with no votes) cannot create a proposal.
    function testGovPropose__CannotCreateProposalIInsufficientVotes() public {
        (address[] memory targets, uint[] memory values, string[] memory sigs, bytes[] memory calldatas) = _generateFakeProposalData();

        vm.prank(stranger);
        vm.expectRevert(NotEligible.selector);
        gov.propose(targets, values, sigs, calldatas, "test");
    }
}


