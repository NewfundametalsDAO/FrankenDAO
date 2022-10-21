pragma solidity ^0.8.13;

import { StakingBase } from "./StakingBase.t.sol";
import "forge-std/Test.sol";

contract StakingParametersTest is StakingBase {

    // can update stake time
    function testBonus__UpdateStakeBonusTime() public {
        (uint maxStakeBonusTime, uint maxStakeBonusAmount) = staking.stakingSettings();

        vm.prank(address(executor));
        staking.changeStakeTime(uint128(maxStakeBonusTime + 1 weeks));

        (uint newMaxStakeBonusTime, uint newMaxStakeBonusAmount) = staking.stakingSettings();
        assert(newMaxStakeBonusTime == maxStakeBonusTime + 1 weeks);
    }

    function testBonus__UpdateStakeBonusAmount() public {
        (uint maxStakeBonusTime, uint maxStakeBonusAmount) = staking.stakingSettings();
        
        vm.prank(address(executor));
        staking.changeStakeAmount(uint128(maxStakeBonusAmount + 1));

        (uint newMaxStakeBonusTime, uint newMaxStakeBonusAmount) = staking.stakingSettings();
        assert(newMaxStakeBonusAmount == maxStakeBonusAmount + 1);
    }

    function testBonus__RewardsDecreaseIfMaxStakedTimeIncreases() public {
        (uint maxStakeBonusTime, uint maxStakeBonusAmount) = staking.stakingSettings();

        uint TOKEN_ID_1 = 0;
        address owner1 = mockStakeSingle(TOKEN_ID_1, block.timestamp + maxStakeBonusTime);
        uint o1bonus = staking.stakedTimeBonus(TOKEN_ID_1);
        assert(o1bonus == maxStakeBonusAmount);
        
        vm.prank(address(executor));
        staking.changeStakeTime(uint128(maxStakeBonusTime + 1 weeks));

        uint TOKEN_ID_2 = 10;
        address owner2 = mockStakeSingle(TOKEN_ID_2, block.timestamp + maxStakeBonusTime);
        uint o2bonus = staking.stakedTimeBonus(TOKEN_ID_2);

        assert(o2bonus < o1bonus);
    }

    function testBonus__RewardsIncreaseIfMaxStakedBonusIncreases() public {
        (uint maxStakeBonusTime, uint maxStakeBonusAmount) = staking.stakingSettings();

        uint TOKEN_ID_1 = 0;
        address owner1 = mockStakeSingle(TOKEN_ID_1, block.timestamp + maxStakeBonusTime);
        uint o1bonus = staking.stakedTimeBonus(TOKEN_ID_1);
        assert(o1bonus == maxStakeBonusAmount);
        
        vm.prank(address(executor));
        staking.changeStakeAmount(uint128(maxStakeBonusAmount + 1));

        uint TOKEN_ID_2 = 10;
        address owner2 = mockStakeSingle(TOKEN_ID_2, block.timestamp + maxStakeBonusTime);
        uint o2bonus = staking.stakedTimeBonus(TOKEN_ID_2);

        assert(o2bonus > o1bonus);
    }

    function testBonus__MaxStakedBonusIncreaseTranslatesToVotingPower() public {
        (uint maxStakeBonusTime, uint maxStakeBonusAmount) = staking.stakingSettings();

        uint TOKEN_ID_1 = 0;
        address owner1 = mockStakeSingle(TOKEN_ID_1, block.timestamp + maxStakeBonusTime);
        uint beforeVotes = staking.getVotes(owner1);

        vm.prank(address(executor));
        staking.changeStakeAmount(uint128(maxStakeBonusAmount + 1));

        uint[] memory ids = new uint[](1);
        ids[0] = TOKEN_ID_1;
        vm.warp(block.timestamp + maxStakeBonusTime);
        vm.prank(owner1);
        staking.unstake(ids, owner1);

        mockStakeSingle(TOKEN_ID_1, block.timestamp + maxStakeBonusTime);
        uint afterVotes = staking.getVotes(owner1);

        assert(afterVotes > beforeVotes);
    }



    // updated stake time affects voting power
    //function testNewStakeBonusTimeChangesCommunityVotingPower() public {}

    // can update stake amount
    //function testUpdateStakeBonusAmount() public {}

    // updated stake amount affects voting power
    //function testNewStakeBonusAmountChangesCommunityVotingPower() public {}
}
