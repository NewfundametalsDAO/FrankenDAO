// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {GovernanceBase} from "../bases/GovernanceBase.t.sol";

contract LockedTests is GovernanceBase {

    // Test that a user can't unstake after voting.
    function testLocking__RevertIfUnstakingAfterVoting() public {
        address owner = mockStakeSingle(PUNK_ID);

        uint proposalId = _createAndVerifyProposal();
        vm.warp(block.timestamp + gov.votingDelay());

        vm.startPrank(owner);
        gov.castVote(proposalId, 1);

        uint[] memory ownerIds = new uint[](1);
        ownerIds[0] = PUNK_ID;

        vm.expectRevert(TokenLocked.selector);
        staking.unstake(ownerIds, owner);
    }

    // Test that a user can't unstake after a delegate has voted.
    function testLocking__RevertIfUnstakingAfterDelegateHasVoted() public {
        address owner = mockStakeSingle(PUNK_ID);
        address delegate = mockStakeSingle(MONSTER_ID);

        vm.prank(owner);
        staking.delegate(delegate);

        uint proposalId = _createAndVerifyProposal();
        vm.warp(block.timestamp + gov.votingDelay());

        vm.prank(delegate);
        gov.castVote(proposalId, 1);

        uint[] memory ownerIds = new uint[](1);
        ownerIds[0] = MONSTER_ID;
        
        vm.prank(owner);
        vm.expectRevert(TokenLocked.selector);
        staking.unstake(ownerIds, owner);
    }

    // Test that a user can't delegate after voting.
    function testLocking__RevertIfDelegatingAfterVoting() public {
        address owner = mockStakeSingle(PUNK_ID);
        address delegate = makeAddr("unstakedDelegate");

        uint proposalId = _createAndVerifyProposal();
        vm.warp(block.timestamp + gov.votingDelay());

        vm.startPrank(owner);
        gov.castVote(proposalId, 1);

        vm.expectRevert(TokenLocked.selector);
        staking.delegate(delegate);
    }

    // Test that tokens are unlocked if a proposal is canceled.
    function testLocking__DelegatingAfterVotingDoesntRevertIfProposalCanceled() public {
        uint proposalId = _createSuccessfulProposal();
        
        vm.startPrank(proposer);
        vm.expectRevert(TokenLocked.selector);
        staking.delegate(voter);

        gov.cancel(proposalId);

        staking.delegate(voter);
        assert(staking.getDelegate(proposer) == voter);
    }

    // Test that tokens are unlocked if proposal is vetoed.
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

    // Test that tokens are unlocked when a proposal is queued.
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
