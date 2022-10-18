pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/Staking.sol";
import "../utils/mocks/Token.sol";

contract CommunityVotingPowerTest is Test {
    Staking staking;
    Token frankenpunk;

    function setUp() public { }

    // ----
    // Multipliers
    // ----
    // update votes multiplier
    // new votes multiplier changes individual community voting power
    // update proposals multiplier
    // new proposals multiplier changes individual community voting power
    // update executed/passed proposals multiplier
    // new executed/passed proposals multiplier changes individual community voting power

    // ----
    // Individual Community Voting Power
    // ----

    // delegating sets my community voting power to 0
    //function testDelegatingSetsCommunityVotingPowerToZero() public {
        // address 1: stake frankenpunk on staking;
        // address 2: stake frankenpunk on staking;
        // address 1: creates proposal
        // address 1: votes on proposal
        // assert community voting power of address 1 is greater than zero;
        // address 1 delegate to address 2;
        // assert community voting power of address 1 is zero;
    //}

    // undelegating resets my community voting power
    //function testUndelegatingResetsCommunityVotingPower() public {
        // addr 1: stake frankenpunk on staking;
        // addr 2: stake frankenpunk on staking;
        // address 1: creates proposal
        // address 1: votes on proposal
        // get initial community voting power of addr 1;
        // addr 1 delegates to addr 2
        // addr 1 undelegates
        // get after voting power
        // assert equal: initial voting power and after voting power
    //}

    // ----
    // Total + Individual Community Voting Power
    // ----

    // proposing increases my community voting power
    //function testProposingIncreasesCommunityVotingPower() {
        // addr 1 initial voting power
        // initial total community voting power

        // addr 1 creates proposal

        // addr 1 new voting power
        // new total comunity voting power

        // addr 1 new voting power > initial
        // total voting power > initial
    //}

    // voting increases my community voting power
    //function testVotingIncreasesCommunityVotingPower() public {
        // create proposal
        // addr 1 initial voting power
        // initial total community voting power

        // addr 1 votes on proposal

        // addr 1 new voting power
        // new total comunity voting power

        // addr 1 new voting power > initial
        // total voting power > initial
    //}

    // proposal passing increases my community voting power
    //function testProposalPassingIncreasesCommunityVotingPower() public {
        // create proposal
        // helper makes proposal pass

        // addr 1 initial voting power
        // initial total community voting power

        // addr 1 passes proposal (queues proposal?)

        // addr 1 new voting power
        // new total comunity voting power

        // addr 1 new voting power > initial
        // total voting power > initial
    //}

    // ----
    // Total Community Voting Power
    // ----

    // delegating doesn't affect total community voting power
    //function testDelegatingDoesntAffectTotalCommunityVotingPower() {
        // addr 1 creates proposal
        // addr 2 votes
        // get initial CVP
        // addr 2 delegates to addr 1
        // get new CVP
        // assert initial CVP eq new CVP
    //}
}

