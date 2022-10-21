pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { GovernanceBase } from "./GovernanceBase.t.sol";
import { IGovernance } from "../../src/interfaces/IGovernance.sol";

contract ActiveProposalTest is GovernanceBase {
    // Test that proposal is in Active Proposals when it's created.
    function testGovActive__ProposalAddedToActive() public {
        uint proposalId = _createProposal();
        uint[] memory activeProposals = gov.getActiveProposals();
        bool found;
        for (uint i = 0; i < activeProposals.length; i++) {
            if (activeProposals[i] == proposalId) {
                found = true;
                break;
            }
        }
        assert(found);
    }

    // Test that we can add two proposals to Active Proposals.
    function testGovActive__TwoProposalsAddedToActive() public {
        uint proposalId1 = _createProposal();
        
        (
            address[] memory targets, 
            uint[] memory values, 
            string[] memory sigs, 
            bytes[] memory calldatas
        ) = _generateFakeProposalData();
        vm.prank(voter);
        uint proposalId2 = gov.propose(targets, values, sigs, calldatas, "test");

        uint[] memory activeProposals = gov.getActiveProposals();
        bool found1;
        bool found2;
        for (uint i = 0; i < activeProposals.length; i++) {
            if (activeProposals[i] == proposalId1) {
                found1 = true;
            }
            if (activeProposals[i] == proposalId2) {
                found2 = true;
            }
        }
        assert(found1 && found2);
        assert(activeProposals.length == 2);
    }

    // Test that a proposal is removed from Active Proposals when it's canceled.
    function testGovActive__ProposalRemovedFromActiveWhenCanceled() public {
        uint proposalId = _createProposal();
        uint[] memory activeProposals = gov.getActiveProposals();
        assert(activeProposals.length == 1);

        vm.prank(proposer);
        gov.cancel(proposalId);

        uint[] memory newActiveProposals = gov.getActiveProposals();
        assert(newActiveProposals.length == 0);
    }

    // Test that a proposal is removed from Active Proposals when it's vetoed.
    function testGovActive__ProposalRemovedFromActiveWhenVetoed() public {
        uint proposalId = _createProposal();
        uint[] memory activeProposals = gov.getActiveProposals();
        assert(activeProposals.length == 1);

        vm.prank(COUNCIL_MULTISIG);
        gov.veto(proposalId);

        uint[] memory newActiveProposals = gov.getActiveProposals();
        assert(newActiveProposals.length == 0);
    }

    // Test that a proposal is removed from Active Proposals when it's queued.
    function testGovActive__ProposalRemovedFromActiveWhenQueued() public {
        uint proposalId = _createSuccessfulProposal();
        uint[] memory activeProposals = gov.getActiveProposals();
        assert(activeProposals.length == 1);

        gov.queue(proposalId);

        uint[] memory newActiveProposals = gov.getActiveProposals();
        assert(newActiveProposals.length == 0);
    }
}
