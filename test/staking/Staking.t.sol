
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/Staking.sol";
import "../utils/mocks/Token.sol";

contract StakingTest is Test {
    Staking staking;
    Token frankenpunk;

    function setUp() public {
        frankenpunk = new Token("FrankenPunks", "PUNK");
        frankenpunk.mint(address(1));
    }

    function testThisWorks() public {
        uint balance = frankenpunk.balanceOf(address(1));
        assertEq(balance, 1);
    }

    // stake frankenpunk
    //function testStakingFrankenPunk() public {
        // mint punk
        // stake to frankenpunk
        // frankenpunk.balanceOf should equal 0
        // staking.balanceOf should equal number staked
    //}

    // transfer reverts for staked FrankenPunks
    //function testStakedTokensAreNotTransferrable() public {
        // mint punk
        // stake punk
        // transfer staked token
        // expect revert
    //}


    // unstake frankenpunk
    //function testUnstakingFrankenPunk() public {
        // stake frankenpunk to staking
        // check that it's staked
        // --- 
        // unstake on staking
        // balance on staking should be zero;
        // balance on frankenpunk should be 1
    //}

    // pause staking
    //function testStakingPaused() public {
        // pause staking
        // check for staking paused event
        // check for staking paused variable on staking
        // ---
        // unpause staking;
        // check for unpaused event;
        // for staking paused variable on staking;
    //}

    // revert staking if paused
    //function testStakingRevertsWhenPaused() public {
        // pause staking
        // try to stake frankenpunk on staking
        // expect revert
    //}

    // revert unstaking if paused
    //function testUnstakingRevertsWhenPaused() public {
        // stake frankenpunk on staking;
        // pause staking;
        // try to unstake frankenpunk from staking;
        // expert revert;
    //}
}

