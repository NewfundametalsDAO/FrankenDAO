pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { GovernanceBase } from "./GovernanceBase.t.sol";
import { IGovernance } from "../../src/interfaces/IGovernance.sol";

contract CommunityPowerTests is GovernanceBase {
    uint64 votesMultiplier;
    uint64 proposalsCreatedMultiplier;
    uint64 proposalsPassedMultiplier;

    function setUp() override public {
        super.setUp();
        (votesMultiplier, proposalsCreatedMultiplier, proposalsPassedMultiplier) = staking.communityPowerMultipliers();
    }

    // Test that voting updates community voting power.
    function testCommunityPower__VotingUpdatesCommunityPower() public {
        uint proposalId = _createAndVerifyProposal();
        vm.warp(block.timestamp + gov.votingDelay());
        assert(_checkState(proposalId, IGovernance.ProposalState.Active));

        assert(staking.getCommunityVotingPower(voter) == 0);
        vm.prank(voter);
        gov.castVote(proposalId, 1);
        
        assert(staking.getCommunityVotingPower(voter) == votesMultiplier / 100);
    }

    // Test that proposing doesn't update community voting power until proposal is verified.
    function testCommunityPower__ProposingDoesntUpdateCommunityPowerUntilVerification() public {
        assert(staking.getCommunityVotingPower(proposer) == 0);
        _createProposal();
        assert(staking.getCommunityVotingPower(proposer) == 0);
    }

    // Test that proposing updates community voting power.
    function testCommunityPower__ProposingUpdatesCommunityPower() public {
        assert(staking.getCommunityVotingPower(proposer) == 0);
        _createAndVerifyProposal();
        assert(staking.getCommunityVotingPower(proposer) == proposalsCreatedMultiplier / 100);
    }

    // Test that passed proposal updates community voting power.
    function testCommunityPower__PassedProposalUpdatesCommunityPower() public {
        assert(staking.getCommunityVotingPower(proposer) == 0);
        uint proposalId = _createSuccessfulProposal();
        assert(staking.getCommunityVotingPower(proposer) == (votesMultiplier + proposalsCreatedMultiplier) / 100);
        gov.queue(proposalId);
        vm.warp(block.timestamp + executor.DELAY());
        gov.execute(proposalId);
        assert(staking.getCommunityVotingPower(proposer) == (votesMultiplier + proposalsCreatedMultiplier + proposalsPassedMultiplier) / 100);
    }

    // Test that updating community multiplers adjusts community voting power as expected.
    function testCommunityPower__UpdatingMultipliersAdjustsCommunityPower() public {
        uint proposalId = _createSuccessfulProposal();
        gov.queue(proposalId);
        vm.warp(block.timestamp + executor.DELAY());
        gov.execute(proposalId);
        
        uint initialPower = (votesMultiplier + proposalsCreatedMultiplier + proposalsPassedMultiplier) / 100;
        assert(staking.getCommunityVotingPower(proposer) == initialPower);

        vm.startPrank(address(executor));
        staking.setVotesMultiplier(votesMultiplier * 2);
        staking.setProposalsCreatedMultiplier(proposalsCreatedMultiplier * 2);
        staking.setProposalsPassedMultiplier(proposalsPassedMultiplier * 2);
        vm.stopPrank();

        assert(staking.getCommunityVotingPower(proposer) == initialPower * 2);
    }

    // Test that delegating sets community voting power to zero.
    function testCommunityPower__DelegatingAndUndelegatingChangeCommunityVotingPower() public {
        uint proposalId = _createSuccessfulProposal();
        assert(staking.getCommunityVotingPower(voter) == votesMultiplier / 100);

        vm.prank(proposer);
        gov.cancel(proposalId);

        vm.prank(voter);
        staking.delegate(proposer);
        assert(staking.getCommunityVotingPower(voter) == 0);

        vm.prank(voter);
        staking.delegate(voter);
        assert(staking.getCommunityVotingPower(voter) == votesMultiplier / 100);
    }

    // Test that total community voting power tracks correctly.
    function testCommunityPower__TotalCommunityVotingPowerTracksCorrectly() public {
        uint proposalId = _createSuccessfulProposal();
        uint voterPower = staking.getCommunityVotingPower(voter);
        uint proposerPower = staking.getCommunityVotingPower(proposer);
        assert(staking.getCommunityVotingPower(address(type(uint160).max)) == voterPower + proposerPower);

        vm.prank(proposer);
        gov.cancel(proposalId);

        vm.startPrank(voter);
        staking.delegate(proposer);
        voterPower = staking.getCommunityVotingPower(voter);
        proposerPower = staking.getCommunityVotingPower(proposer);
        assert(staking.getCommunityVotingPower(address(type(uint160).max)) == voterPower + proposerPower);

        staking.delegate(voter);
        voterPower = staking.getCommunityVotingPower(voter);
        proposerPower = staking.getCommunityVotingPower(proposer);
        assert(staking.getCommunityVotingPower(address(type(uint160).max)) == voterPower + proposerPower);
        vm.stopPrank();
    }
}

