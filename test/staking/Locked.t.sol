pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/Staking.sol";

import {GovernanceBase} from "../governance/GovernanceBase.t.sol";

contract LockedTest is GovernanceBase {
    uint[] ids = [1553, 8687];

    function testLocking__RevertIfUnstakingAfterVoting() public {
        address playerOne = mockStakeSingle(ids[0]);

        uint proposalId = _createAndVerifyProposal();
        vm.warp(block.timestamp + gov.votingDelay());

        vm.startPrank(playerOne);
        gov.castVote(proposalId, 1);

        uint[] memory playerOneIds = new uint[](1);
        playerOneIds[0] = ids[0];

        vm.expectRevert(TokenLocked.selector);
        staking.unstake(playerOneIds, playerOne);
    }
    // @todo come back after implementing voting and proposing tests
    function testLocking__RevertIfUnstakingAfterDelegateHasVoted() public {
        address playerOne = mockStakeSingle(ids[0]);
        address playerTwo = mockStakeSingle(ids[1]);

        vm.prank(playerTwo);
        staking.delegate(playerOne);

        uint proposalId = _createAndVerifyProposal();
        vm.warp(block.timestamp + gov.votingDelay());

        vm.prank(playerOne);
        gov.castVote(proposalId, 1);

        vm.startPrank(playerTwo);
        uint[] memory playerTwoIds = new uint[](1);
        playerTwoIds[0] = ids[1];

        vm.expectRevert(TokenLocked.selector);
        staking.unstake(playerTwoIds, playerTwo);
    }

    // revert if delegating after voting
    function testLocking__RevertIfDelegatingAfterVoting() public {
        address playerOne = mockStakeSingle(ids[0]);
        address playerTwo = mockStakeSingle(ids[1]);

        uint proposalId = _createAndVerifyProposal();
        vm.warp(block.timestamp + gov.votingDelay());

        vm.startPrank(playerOne);
        gov.castVote(proposalId, 1);

        vm.expectRevert(TokenLocked.selector);
        staking.delegate(playerTwo);
    }

    // Test that delegating after voting doesn't revert if proposal is canceled.
    function testLocking__DelegatingAfterVotingDoesntRevertIfProposalCanceled() public {
        uint proposalId = _createSuccessfulProposal();
        
        vm.startPrank(proposer);
        vm.expectRevert(TokenLocked.selector);
        staking.delegate(voter);

        gov.cancel(proposalId);

        staking.delegate(voter);
        assert(staking.getDelegate(proposer) == voter);
    }

    // Test that delegating after voting doesn't revert if proposal is vetoed.
    function testLocking__DelegatingAfterVotingDoesntRevertIfProposalVetoed() public {
        uint proposalId = _createSuccessfulProposal();
        
        vm.prank(proposer);
        vm.expectRevert(TokenLocked.selector);
        staking.delegate(voter);

        vm.prank(FOUNDER_MULTISIG);
        gov.veto(proposalId);

        vm.prank(proposer);
        staking.delegate(voter);
        assert(staking.getDelegate(proposer) == voter);
    }

    // Test that delegating after voting doesn't revert if proposal is queued.
    function testLocking__DelegatingAfterVotingDoesntRevertIfProposalQueued() public {
        uint proposalId = _createSuccessfulProposal();
        
        vm.startPrank(proposer);
        vm.expectRevert(TokenLocked.selector);
        staking.delegate(voter);

        gov.queue(proposalId);

        staking.delegate(voter);
        assert(staking.getDelegate(proposer) == voter);
    }

}
