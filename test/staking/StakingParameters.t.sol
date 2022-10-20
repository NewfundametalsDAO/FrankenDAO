pragma solidity ^0.8.13;

import { StakingBase } from "./StakingBase.t.sol";

contract StakingParametersTest is StakingBase {

    // can update stake time
    function testBonus__UpdateStakeBonusTime() public {
        (uint maxStakeBonusTime, uint maxStakeBonusAmount) = staking.stakingSettings();
        assert(maxStakeBonusTime == 4 weeks);

        vm.prank(address(executor));
        staking.changeStakeTime(5 weeks);

        (uint newMaxStakeBonusTime, uint newMaxStakeBonusAmount) = staking.stakingSettings();
        assert(newMaxStakeBonusTime == 5 weeks);
    }

    function testBonus__UpdateStakeBonusTime() public {
        (uint maxStakeBonusTime, uint maxStakeBonusAmount) = staking.stakingSettings();

        address owner1 = mockStakeSingle(0, block.timestamp + maxStakeBonusTime);
        uint o1bonus = staking.stakedTimeBonus(owner1);
        assert(o1bonus == maxStakeBonusAmount);

        vm.prank(address(executor));
        staking.changeStakeTime(maxStakeBonusTime + 1 weeks);

        address owner2 = mockStakeSingle(0, block.timestamp + maxStakeBonusTime);
        uint o2bonus = staking.stakedTimeBonus(owner2);

        assert(o2bonus < o1bonus);
    }

    // get voting power (should be 0)
        // set stake bonus to 0
        // stake
        // get voting power (should be the same)
        // set stake bonus to 2
        // get voting power (should be x2)

    // updated stake time affects voting power
    //function testNewStakeBonusTimeChangesCommunityVotingPower() public {}

    // can update stake amount
    //function testUpdateStakeBonusAmount() public {}

    // updated stake amount affects voting power
    //function testNewStakeBonusAmountChangesCommunityVotingPower() public {}
}
