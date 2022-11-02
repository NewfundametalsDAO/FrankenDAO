// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { GovernanceBase } from "../bases/GovernanceBase.t.sol";
import { IGovernance } from "../../src/interfaces/IGovernance.sol";

contract ProposalDataTests is GovernanceBase {
    
    // Test that a proposal returns the correct actions.
    function testGovData__ProposalReturnsCorrectActions() public {
        uint proposalId = _createProposal();
        (
            address[] memory targets, 
            uint[] memory values, 
            string[] memory sigs, 
            bytes[] memory calldatas
        ) = _generateFakeProposalData();
        (
            address[] memory govTargets, 
            uint[] memory govValues, 
            string[] memory govSigs, 
            bytes[] memory govCalldatas
        ) = gov.getActions(proposalId);

        for (uint i = 0; i < targets.length; i++) {
            assert(targets[i] == govTargets[i]);
            assert(values[i] == govValues[i]);
            assert(keccak256(bytes(sigs[i])) == keccak256(bytes(govSigs[i])));
            assert(keccak256(calldatas[i]) == keccak256(govCalldatas[i]));
        }
    }

    // Test that the proposal returns the correct data.
    function testGovData__ProposalReturnsCorrectData() public {
        uint proposalId = _createProposal();
        (
            uint id,
            address proposalProposer,
            uint proposerThreshold,
            uint quorumVotes
        ) = gov.getProposalData(proposalId);

        assert(id == proposalId);
        assert(proposalProposer == proposer);
        assert(proposerThreshold == 1400 * gov.proposalThresholdBPS() / 1e5);
        assert(quorumVotes == (1400 * gov.quorumVotesBPS() / 1e5));
    }

    // Test that the proposal returns the correct status information.
    function testGovData__ProposalReturnsCorrectStatus() public {
        uint proposalId = _createProposal();
        (
            bool verified,
            bool canceled,
            bool vetoed,
            bool executed
        ) = gov.getProposalStatus(proposalId);

        assert(!verified && !canceled && !vetoed && !executed);
    }

    // Test that the proposal returns the correct vote information.
    function testGovData__ProposalReturnsCorrectVotes() public {
        uint proposalId = _createAndVerifyProposal();

        vm.warp(block.timestamp + gov.votingDelay());

        _vote(proposalId, 2, true);

        (
            uint yesVotes,
            uint noVotes,
            uint abstainVotes
        ) = gov.getProposalVotes(proposalId);

        assert(yesVotes == 22); // 20 + 2 community power for proposing
        assert(noVotes == 0);
        assert(abstainVotes == 120);
    }

    // Test that the proposal returns the correct receipt.
    function testGovData__ProposalReturnsCorrectReceipt(uint8 support, bool voted) public {
        vm.assume(support < 3);
        uint proposalId = _createAndVerifyProposal();

        vm.warp(block.timestamp + gov.votingDelay() + 1);

        _vote(proposalId, support, voted);

        IGovernance.Receipt memory receipt = gov.getReceipt(proposalId, voter);
        bool hasVoted = receipt.hasVoted;
        uint8 supportGiven = receipt.support;
        uint votes = receipt.votes;

        assert(hasVoted == voted);
        assert(!voted || support == supportGiven);
        assert(!voted || votes == 120);        
    }
}
