pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/Staking.sol";
import "../utils/mocks/Token.sol";

contract GettersTest is Test {

    function setUp() public { }
    // getVotes
    //function testGetVotes() {
        // addr 1 stake
        // addr 2 stake
        // initial voting power: getVotes
        // expect initial voting power to equal ?

        // addr 2 delegate to addr 1
        // new voting power = getVOtes
        // expect new voting power > initial voting power
        // expect new voting power to equal ?

        // create proposal
        // new new voting power = getVotes
        // expect new new voting power > new voting power > initial voting power
    //}

    // getTokenVotingPower
    //function testGetTokenVotingPower() {
        // stake time, evil bonus, punk v monster
        // stake token 1, evil bonus, punk
        // stake token 2, evil bonus punk
        // stake token 10001, no evil bonus, monster
    //}

    // delegate - get my address if I haven't delegated
    //function testDelegateToSelfByDefault() public {
        // addr 1 stakes
        // get current delegate of addr 1
        // delegate == addr 1
    //}

    // delegate - get delegate address if I have delegated
    //function testGetDelegateAddress() public {
        // addr 1 stakes
        // addr 2 stakes
        // addr 2 delegates to addr 1
        // getDelegate(addr 2) == addr 1
    //}
}
