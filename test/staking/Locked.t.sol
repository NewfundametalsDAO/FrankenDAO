pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/Staking.sol";
import "../utils/mocks/Token.sol";

contract LockedTest is Test {
    Staking staking;
    Token frankenpunk;

    function setUp() public { }

    // reverts if unstaking during a vote
    //function testRevertsIfUnstakingDuringVoting() public {
        // addr 1 stakes
        // addr 2 stakes
        // addr 2 delegates to addr 1
        // create proposal
        // addr 1 votes
        // addr 2 unstakes
        // expect revert
    // }

    // reverts if delegating during a vote
    // function testRevertsIfDelegatingDuringVoting() public {
        // addr 1 stakes
        // addr 2 stakes
        // addr 2 delegates to addr 1
        // create proposal
        // addr 1 votes
        // addr 2 delegates back to themselves
        // expect revert
    // }
}
