pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/Staking.sol";
import "../utils/mocks/Token.sol";

contract StakingParametersTest is Test {
    Staking staking;
    Token frankenpunk;

    function setUp() public { }

    // can update stake time
    //function testUpdateStakeBonusTime() public {
        // get voting power (should be 0)
        // set stake bonus to 0
        // stake
        // get voting power (should be the same)
        // set stake bonus to 2
        // get voting power (should be x2)
    //}

    // updated stake time affects voting power
    //function testNewStakeBonusTimeChangesCommunityVotingPower() public {}

    // can update stake amount
    //function testUpdateStakeBonusAmount() public {}

    // updated stake amount affects voting power
    //function testNewStakeBonusAmountChangesCommunityVotingPower() public {}
}
