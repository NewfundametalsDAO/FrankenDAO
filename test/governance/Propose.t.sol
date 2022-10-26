pragma solidity ^0.8.13;

import { GovernanceBase } from "./GovernanceBase.t.sol";
import { IGovernance } from "../../src/interfaces/IGovernance.sol";

contract ProposeTest is GovernanceBase {
    // Test that a proposal can be created by the proposer
    function testGovPropose__CanCreatePendingProposal() public {
        uint proposalId = _createProposal();
        assert(gov.state(proposalId) == IGovernance.ProposalState.Pending);
    }

    // Test that a stranger (someone with no votes) cannot create a proposal.
    function testGovPropose__CannotCreateProposalIInsufficientVotes() public {
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

    // Cant propose if already proposed
    function testGovPropose__CannotCreateProposalIfAlreadyProposed() public {
        uint proposalId = _createProposal();
        vm.expectRevert(NotEligible.selector);
        uint proposalId2 = _createProposal();
    }

    // ADD TESTS FOR MULTIPLE PROPOSALS, SAME BLOCK, SEP BLOCKS, ETC
}


