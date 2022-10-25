pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { GovernanceBase } from "./GovernanceBase.t.sol";
import { IGovernance } from "../../src/interfaces/IGovernance.sol";

contract CommunityPowerTests is GovernanceBase {
    // Test that voting updates community voting power.
    function testCommunityPower__VotingUpdatesCommunityPower() public {
        uint proposalId = _createAndVerifyProposal();
        vm.warp(block.timestamp + gov.votingDelay());
        assert(_checkState(proposalId, IGovernance.ProposalState.Active));

        assert(staking.getCommunityVotingPower(voter) == 0);
        vm.prank(voter);
        gov.castVote(proposalId, 1);
        assert(staking.getCommunityVotingPower(voter) == 1);
    }
}
// voting updates community voting power
// proposing updates community voting power
// executing updates community voting power
// changint he multipliers works as expected

