pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/Staking.sol";
import "../utils/mocks/Token.sol";

contract VotingPowerTest is Test {
    Staking staking;
    Token frankenpunk;

    function setUp() public { }

    // staking updates voting power
    //function testStakingIncreasesIndividualVotingPower() public {
        // get initial voting power (should be zero)
        // stake
        // calculate what increase should be
        // get new VP
        // assert VP == initial VP + calculated increase from staking
    //}

    // unstaking updates voting power
    //function testUnstakingDecreasesIndividualVotingPower() public {
        // stake
        // get initial voting power
        // calculate what VP decrease should be
        // unstake
        // get new VP
        // assert VP == initial VP - calculated decrease from staking
    //}

    // delegating updates voting power
    //function testDelegatingIncreasesVotingPower() public {
        // addr 1 stake
        // addr 2 stake
        // get initial VP for addr 1
        // get initial VP for addr 2
        // addr 2 delegate to addr 1
        // get new VP for addr 1
        // assert new VP = inivial VP from addr 1 + initial VP from addr 2
    //}

    // undelegating updates voting power
    //function testUndelegatingDecreasesVotingPower() public {
        // addr 1 stake
        // addr 2 stake
        // get initial VP for addr 2
        // addr 2 delegate to addr 1
        // get initial VP for addr 1
        // addr 2 undelegates from addr 1
        // get new VP for addr 1
        // assert new VP = initial VP from addr 1 - VP from addr 2
    //}

    // total voting power is combination of VP + CVP
    //function testTotalVotingPower() public {
        // addr 1 stake
        // addr 1 creates proposal
        // get addr 1 community voting power
        // get addr 1 token holding voting power
        // assert total voting power == community VP + token VP

        // addr 1 votes on proposal
        // get new total VP
        //assert new votal VP > old total VP
        // assert new total VP = old total VP + (1 * multiple)
    //}
}
