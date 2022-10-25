pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/Staking.sol";
import "../utils/mocks/Token.sol";

import {GovernanceBase} from "../governance/GovernanceBase.sol";

contract LockedTest is GovernanceBase {
    uint[] ids = [6251, 4122];

    // reverts if unstaking during a vote
    function testLocking__RevertsIfUnstakingDuringVoting() public {
        // addr 1 stakes
        address playerOne = mockStakeSingle(ids[0]);
        // addr 2 stakes
        address playerTwo = mockStakeSingle(ids[1]);

        // addr 2 delegates to addr 1
        vm.prank(playerOne);
        frankenpunks.delegate(playerOne);

        // create proposal

        // addr 1 votes
        vm.prank(playerOne);
        govImpl.castVote(proposalId, 1);

        // expect revert
        vm.prank(playerTwo);
        vm.expectRevert(TokenLocked.selector);
        // addr 2 unstakes
        frankenpunks.unstake(ids[1], playerTwo);
     }

    // reverts if delegating during a vote
    // function testLocking__RevertsIfDelegatingDuringVoting() public {
        // addr 1 stakes
        // addr 2 stakes
        // addr 2 delegates to addr 1
        // create proposal
        // addr 1 votes
        // addr 2 delegates back to themselves
        // expect revert
    // }
}
