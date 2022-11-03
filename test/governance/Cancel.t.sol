// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { IGovernance } from "../../src/interfaces/IGovernance.sol";
import { GovernanceBase } from "../bases/GovernanceBase.t.sol";

contract CancelProposalTests is GovernanceBase {
    // Test that a user can cancel their own proposal right away.
    function testGovCancel__UserCanCancelOwnProposal() public {
        uint proposalId = _createProposal();
        assert(_checkState(proposalId, IGovernance.ProposalState.Pending));

        vm.prank(proposer);
        gov.cancel(proposalId);

        assert(_checkState(proposalId, IGovernance.ProposalState.Canceled));
    }

    // Test that a user can cancel their own proposal after voting starts.
    function testGovCancel__UserCanCancelOwnProposalAfterVotingStarts() public {
        uint proposalId = _createAndVerifyProposal();
        vm.warp(block.timestamp + gov.votingDelay() + 10);
        assert(_checkState(proposalId, IGovernance.ProposalState.Active));

        _vote(proposalId, 1, true);

        vm.prank(proposer);
        gov.cancel(proposalId);

        assert(_checkState(proposalId, IGovernance.ProposalState.Canceled));
    }

    // Test that a user can cancel their proposal after it's queued.
    function testGovCancel__UserCanCancelOwnProposalAfterQueued() public {
        uint proposalId = _createSuccessfulProposal();
        gov.queue(proposalId);
        assert(_checkState(proposalId, IGovernance.ProposalState.Queued));
        (
            address[] memory targets, 
            uint[] memory values, 
            string[] memory sigs, 
            bytes[] memory calldatas
        ) = _generateFakeProposalData();

        bytes32 txHash = keccak256(abi.encode(targets[0], values[0], sigs[0], calldatas[0], block.timestamp + executor.DELAY()));
        assert(executor.queuedTransactions(txHash));
        assert(_checkState(proposalId, IGovernance.ProposalState.Queued));

        vm.prank(proposer);
        gov.cancel(proposalId);

        assert(_checkState(proposalId, IGovernance.ProposalState.Canceled));
        assert(!executor.queuedTransactions(txHash));
    }

    // Test that a proposal cannot be canceled twice.
    function testGovCancel__ProposalCannotBeCanceledTwice() public {
        uint proposalId = _createProposal();
        assert(_checkState(proposalId, IGovernance.ProposalState.Pending));

        vm.startPrank(proposer);
        gov.cancel(proposalId);

        assert(_checkState(proposalId, IGovernance.ProposalState.Canceled));

        vm.expectRevert(InvalidStatus.selector);
        gov.cancel(proposalId);
    }

    // Test that nobody can cancel a proposal right when it's created.
    function testGovCancel__NobodyCanCancelUnlessThingsChange() public {
        uint proposalId = _createProposal();
        assert(_checkState(proposalId, IGovernance.ProposalState.Pending));

        vm.prank(voter);
        vm.expectRevert(NotEligible.selector);
        gov.cancel(proposalId);
    }

    // Test that the proposal is automatically canceled if it isn't verified after endTime.
    function testGovCancel__AutomaticallyCanceledIfProposalNotVerifiedAfterEndTime() public {
        uint proposalId = _createProposal();
        assert(_checkState(proposalId, IGovernance.ProposalState.Pending));

        vm.warp(block.timestamp + gov.votingDelay() + gov.votingPeriod() + 10);

        assert(_checkState(proposalId, IGovernance.ProposalState.Canceled));
    }

    // Test that anyone can clear an autocanceled proposal.
    function testGovCancel__AnyoneCanClearAutocanceledProposal() public {
        uint proposalId = _createProposal();
        assert(_checkState(proposalId, IGovernance.ProposalState.Pending));

        vm.warp(block.timestamp + gov.votingDelay() + gov.votingPeriod() + 10);

        assert(_checkState(proposalId, IGovernance.ProposalState.Canceled));
        assert(gov.getActiveProposals().length == 1);

        vm.prank(stranger);
        gov.clear(proposalId);

        assert(_checkState(proposalId, IGovernance.ProposalState.Canceled));
        assert(gov.getActiveProposals().length == 0);
    }
    
    // Test that anyone can clear if a proposal (removing it from executor queue) if isn't executed within the grace period.
    function testGovCancel__AnyoneCanClearIfProposalNotExecutedWithinGracePeriod() public {
        uint proposalId = _createSuccessfulProposal();
        
        (
            address[] memory targets, 
            uint[] memory values, 
            string[] memory sigs, 
            bytes[] memory calldatas
        ) = _generateFakeProposalData();

        bytes32 txHash = keccak256(abi.encode(targets[0], values[0], sigs[0], calldatas[0], block.timestamp + executor.DELAY()));
        gov.queue(proposalId);
        assert(_checkState(proposalId, IGovernance.ProposalState.Queued));
        assert(executor.queuedTransactions(txHash));

        vm.warp(block.timestamp + executor.DELAY() + executor.GRACE_PERIOD() + 1);
        vm.prank(stranger);
        gov.clear(proposalId);

        assert(!executor.queuedTransactions(txHash));
        assert(_checkState(proposalId, IGovernance.ProposalState.Expired));
    }

    // Test that anyone can clear a proposal (removing it from Active Proposals array) once it is defeated.
    function testGovCancel__ProposalCanBeClearedWhenDefeated() public {
        uint proposalId = _createAndVerifyProposal();
        vm.warp(block.timestamp + gov.votingDelay());
        gov.castVote(proposalId, 0);
        vm.warp(block.timestamp + gov.votingPeriod() + 1);

        assert(_checkState(proposalId, IGovernance.ProposalState.Defeated));

        uint[] memory activeProposals = gov.getActiveProposals();

        vm.prank(stranger);
        gov.clear(proposalId);

        uint[] memory newActiveProposals = gov.getActiveProposals();

        assert(activeProposals.length == newActiveProposals.length + 1);
        assert(_checkState(proposalId, IGovernance.ProposalState.Defeated));
    }

    // Test that you can't cancel a defeated proposal.
    function testGovCancel__CantCancelDefeatedProposal() public {
        uint proposalId = _createAndVerifyProposal();
        assert(_checkState(proposalId, IGovernance.ProposalState.Pending));

        vm.warp(block.timestamp + gov.votingDelay() + gov.votingPeriod() + 10);

        vm.prank(proposer);
        vm.expectRevert(InvalidStatus.selector);
        gov.cancel(proposalId);
    }

    // Test that you can clear a defeated proposal.
    function testGovCancel__CanClearDefeatedProposal() public {
        uint proposalId = _createAndVerifyProposal();
        assert(_checkState(proposalId, IGovernance.ProposalState.Pending));

        vm.warp(block.timestamp + gov.votingDelay() + gov.votingPeriod() + 10);

        assert(gov.getActiveProposals().length == 1);

        vm.prank(stranger);
        gov.clear(proposalId);

        assert(_checkState(proposalId, IGovernance.ProposalState.Defeated));
        assert(gov.getActiveProposals().length == 0);
    }

    // Test that a proposal cannot be canceled after it is executed.
    function testGovCancel__ProposalCannotBeCanceledAfterExecuted() public {
        uint proposalId = _createSuccessfulProposal();
        gov.queue(proposalId);
        vm.warp(block.timestamp + executor.DELAY());
        gov.execute(proposalId);

        vm.prank(proposer);
        vm.expectRevert(InvalidStatus.selector);
        gov.cancel(proposalId);
    }
}