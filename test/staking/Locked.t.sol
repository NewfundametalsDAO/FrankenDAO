pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/Staking.sol";
import "../utils/mocks/Token.sol";

import { StakingBase } from "./StakingBase.t.sol";

contract LockedTest is StakingBase {
    // @todo come back after implementing voting and proposing tests

    // @todo revert if unstaking after delegatee has voted
    // function testPausing__RevertIfUnstakeDuringVoting() public {
    //     address owner = mockStakeSingle(ID);
    //     vm.prank(owner);
    //     vm.expectRevert("cannot unstake during voting");
    //     staking.unstake(ID);
     //}

    // @todo reverts if unstaking during a vote
    //function testPausing__RevertsIfUnstakingDuringVoting() public {
        // addr 1 stakes
        // addr 2 stakes
        // addr 2 delegates to addr 1
        // create proposal
        // addr 1 votes
        // addr 2 unstakes
        // expect revert
    // }

    // @tod reverts if delegating during a vote
    // function testPausing__RevertsIfDelegatingDuringVoting() public {
        // addr 1 stakes
        // addr 2 stakes
        // addr 2 delegates to addr 1
        // create proposal
        // addr 1 votes
        // addr 2 delegates back to themselves
        // expect revert
    // }
}
