pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { GovernanceBase } from "../bases/GovernanceBase.t.sol";
import { IGovernance } from "../../src/interfaces/IGovernance.sol";

contract CastVoteTest is GovernanceBase {
    // Test that voting is not allowed on an unverified proposal.
    function testGovVote__RevertIfProposalNotVerified() public {
        uint proposalId = _createProposal();
        
        vm.warp(block.timestamp + gov.votingDelay() + 1);

        vm.prank(voter);
        vm.expectRevert(InvalidStatus.selector);
        gov.castVote(proposalId, 1);
    }

    // Test that voting is not allowed if the voter has already voted.
    function testGovVote__RevertIfAlreadyVoted() public {
        uint proposalId = _createAndVerifyProposal();

        vm.warp(block.timestamp + gov.votingDelay() + 1);
        
        vm.prank(voter);
        gov.castVote(proposalId, 1);

        vm.prank(voter);
        vm.expectRevert(AlreadyVoted.selector);
        gov.castVote(proposalId, 1);
    }

    // Test that voting is not allowed after the voting period has ended.
    function testGovVote__RevertIfVotingPeriodEnded() public {
        uint proposalId = _createAndVerifyProposal();

        vm.warp(block.timestamp + gov.votingDelay() + gov.votingPeriod() + 1);

        vm.prank(voter);
        vm.expectRevert(InvalidStatus.selector);
        gov.castVote(proposalId, 1);
    }
}
