pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { GovernanceBase } from "./GovernanceBase.t.sol";
import { IGovernance } from "../../src/interfaces/IGovernance.sol";

contract ProposalStateTests is GovernanceBase {
    // Test that a newly created proposal is set to Pending.
    function testGovState__ProposalPendingIfNoActionTaken() public {
        uint proposalId = _createProposal();
        assert(_checkState(proposalId, IGovernance.ProposalState.Pending));
    }

    // Test that once a proposal is verified, it stays pending until start block.
    function testGovState__VerifiedProposalPendingUntilStartBlock() public {
        uint proposalId = _createProposal();
        vm.prank(COUNCIL_MULTISIG);
        gov.verifyProposal(proposalId);
        assert(_checkState(proposalId, IGovernance.ProposalState.Pending));
    }

    // Test that once a proposal is verified, the council multisig can verify it.
    function testGovState__CouncilCanVerifyProposal() public {
        uint proposalId = _createProposal();

        vm.prank(COUNCIL_MULTISIG);
        gov.verifyProposal(proposalId);

        // @todo switch this to warp when switching to times
        vm.roll(block.number + gov.votingDelay());

        assert(_checkState(proposalId, IGovernance.ProposalState.Active));
    }

    // Test that once a proposal is created, the founder multisig can verify it.
    function testGovState__FounderCanVerifyProposal() public {
        uint proposalId = _createProposal();

        vm.prank(FOUNDER_MULTISIG);
        gov.verifyProposal(proposalId);

        // @todo switch this to warp when switching to times
        vm.roll(block.number + gov.votingDelay());
        
        assert(_checkState(proposalId, IGovernance.ProposalState.Active));
    }

    // Test that a proposal can be verified after the start block.
    function testGovState__ProposalCanBeVerifiedAfterStartBlock() public {
        uint proposalId = _createProposal();

        // @todo switch this to warp when switching to times
        vm.roll(block.number + gov.votingDelay() + 10);
        
        vm.prank(COUNCIL_MULTISIG);
        gov.verifyProposal(proposalId);
        
        assert(_checkState(proposalId, IGovernance.ProposalState.Active));
    }

    // Test that a proposal will shift to canceled if no action happens until the end block.
    function testGovState__ProposalCancelledIfNoActionTakenUntilEndBlock() public {
        uint proposalId = _createProposal();

        // @todo switch this to warp when switching to times
        vm.roll(block.number + gov.votingDelay() + gov.votingPeriod() + 1);

        assert(_checkState(proposalId, IGovernance.ProposalState.Canceled));
    }

    // Test that a proposal cannot be verified after the end block.
    function testGovState__ProposalCantBeVerifiedAfterEndBlock() public {
        uint proposalId = _createProposal();

        // @todo switch this to warp when switching to times
        vm.roll(block.number + gov.votingDelay() + gov.votingPeriod() + 1);

        vm.prank(COUNCIL_MULTISIG);
        vm.expectRevert(InvalidStatus.selector);
        gov.verifyProposal(proposalId);
    }

    // Test that a proposal can be vetoed by the council multisig before becoming active.
    function testGovPropose__CouncilCanVetoProposal() public {
        uint proposalId = _createProposal();

        vm.prank(COUNCIL_MULTISIG);
        gov.veto(proposalId);
        
        assert(_checkState(proposalId, IGovernance.ProposalState.Vetoed));
    }

    // Test that a proposal can be vetoed after being verified.
    function testGovPropose__CouncilCanVetoVerifiedProposal() public {
        uint proposalId = _createAndVerifyProposal();

        // @todo switch this to warp when switching to times
        vm.roll(block.number + gov.votingDelay());

        gov.veto(proposalId);
        assert(_checkState(proposalId, IGovernance.ProposalState.Vetoed));
    }

    // Test that a proposal remains active until the end block, regardless of votes.
    function testGovPropose__ProposalRemainsActiveUntilEndBlock() public {
        uint proposalId = _createAndVerifyProposal();

        // @todo switch this to warp when switching to times
        vm.roll(block.number + gov.votingDelay());

        _vote(proposalId, 1, true);

        // @todo switch this to warp when switching to times
        vm.roll(block.number + gov.votingPeriod() - 1);

        assert(_checkState(proposalId, IGovernance.ProposalState.Active));
    }

    // Test that proposal passes if it has the majority of votes and hits quorum.
    function testGovPropose__ProposalSucceedsIfGetsEnoughVotes() public {
        uint proposalId = _createAndVerifyProposal();

        // @todo switch this to warp when switching to times
        vm.roll(block.number + gov.votingDelay());

        _vote(proposalId, 1, true); // voter votes for proposal

        // @todo switch this to warp when switching to times
        vm.roll(block.number + gov.votingPeriod() + 1);

        assert(_checkState(proposalId, IGovernance.ProposalState.Succeeded));
    }

    // Test that a proposal fails if the majority votes against it.
    function testGovPropose__ProposalFailsIfMajorityVotesAgainst() public {
        uint proposalId = _createAndVerifyProposal();

        // @todo switch this to warp when switching to times
        vm.roll(block.number + gov.votingDelay());

        _vote(proposalId, 0, true); // voter votes against proposal

        // @todo switch this to warp when switching to times
        vm.roll(block.number + gov.votingPeriod() - 1);

        assert(_checkState(proposalId, IGovernance.ProposalState.Succeeded));
    }

    // Test that a proposal fails if it doesn't hit quorum.
    function testGovPropose__ProposalFailsIfDoesntReachQuorum() public {
        uint proposalId = _createAndVerifyProposal();

        // @todo switch this to warp when switching to times
        vm.roll(block.number + gov.votingDelay());

        _vote(proposalId, 1, false); // voter doesn't vote

        // @todo switch this to warp when switching to times
        vm.roll(block.number + gov.votingPeriod() - 1);

        assert(_checkState(proposalId, IGovernance.ProposalState.Defeated));
    }

    // Test that anyone can queue a proposal once it passes.
    function testGovPropose__AnyoneCanQueueProposal() public {
        uint proposalId = _createSuccessfulProposal();

        vm.prank(stranger);
        gov.queue(proposalId);
        assert(_checkState(proposalId, IGovernance.ProposalState.Queued));

        (
            address[] memory targets, 
            uint[] memory values, 
            string[] memory sigs, 
            bytes[] memory calldatas
        ) = _generateFakeProposalData();

        for (uint i = 0; i < targets.length; i++) {
            bytes32 txHash = _getTxHash(targets[i], values[i], sigs[i], calldatas[i], block.timestamp + executor.DELAY());
            assert(executor.queuedTransactions(txHash));
        }
    }

    // Test that nobody can queue a proposal before it completes.
    function testGovPropose__NobodyCanQueueProposalBeforeItPasses() public {
        uint proposalId = _createAndVerifyProposal();

        // @todo switch this to warp when switching to times
        vm.roll(block.number + gov.votingDelay());

        _vote(proposalId, 1, true); // voter votes for proposal

        vm.prank(stranger);
        vm.expectRevert(InvalidStatus.selector);
        gov.queue(proposalId);
    }

    // Test that a proposal can be vetoed after it has been queued.
    function testGovPropose__ProposalCanBeUnqueuedByVeto() public {
        uint proposalId = _createSuccessfulProposal();

        vm.prank(stranger);
        gov.queue(proposalId);
        assert(_checkState(proposalId, IGovernance.ProposalState.Queued));

        vm.prank(FOUNDER_MULTISIG);
        gov.veto(proposalId);

        assert(_checkState(proposalId, IGovernance.ProposalState.Vetoed));

        (
            address[] memory targets, 
            uint[] memory values, 
            string[] memory sigs, 
            bytes[] memory calldatas
        ) = _generateFakeProposalData();

        for (uint i = 0; i < targets.length; i++) {
            bytes32 txHash = _getTxHash(targets[i], values[i], sigs[i], calldatas[i], block.timestamp + executor.DELAY());
            assert(!executor.queuedTransactions(txHash));
        }
    }

    // Test that queued transaction can be executed by anyone after the delay.
    // function testGovPropose__ExecutionSucceedsAndClearsQueue() public {
    //     uint proposalId = _createSuccessfulProposal();

    //     vm.prank(stranger);
    //     gov.queue(proposalId);

    //     vm.warp(block.timestamp + executor.DELAY());

    //     vm.prank(stranger);
    //     assert(gov.votingPeriod() == 7 days);
    //     gov.execute(proposalId);
    //     assert(_checkState(proposalId, IGovernance.ProposalState.Executed));
    //     assert(gov.votingPeriod() == 6 days);

    //     for (uint i = 0; i < targets.length; i++) {
    //         bytes32 txHash = _getTxHash(targets[i], values[i], sigs[i], calldatas[i], block.timestamp + executor.DELAY());
    //         assert(!executor.queuedTransactions(txHash));
    //     }
    // }

    function _checkState(uint proposalId, IGovernance.ProposalState targetState) internal returns (bool) {
        IGovernance.ProposalState proposalState = gov.state(proposalId);
        return proposalState == targetState;
    }

    function _createProposal() public returns (uint) {
        (
            address[] memory targets, 
            uint[] memory values, 
            string[] memory sigs, 
            bytes[] memory calldatas
        ) = _generateFakeProposalData();

        vm.prank(proposer);
        return gov.propose(targets, values, sigs, calldatas, "test");
    }

    function _createAndVerifyProposal() public returns (uint) {
        uint proposalId = _createProposal();
        vm.prank(COUNCIL_MULTISIG);
        gov.verifyProposal(proposalId);
        return proposalId;
    }

    function _createSuccessfulProposal() public returns (uint) {
        uint proposalId = _createAndVerifyProposal();

        // @todo switch this to warp when switching to times
        vm.roll(block.number + gov.votingDelay());

        _vote(proposalId, 1, true); // voter votes for proposal

        // @todo switch this to warp when switching to times
        vm.roll(block.number + gov.votingPeriod() + 1);

        return proposalId;
    }

    function _vote(uint proposalId, uint8 voterVote, bool voterVotes) internal {
        vm.prank(proposer);
        gov.castVote(proposalId, 1);
        if (voterVotes) {
            vm.prank(voter);
            gov.castVote(proposalId, voterVote);
        }
    }
}