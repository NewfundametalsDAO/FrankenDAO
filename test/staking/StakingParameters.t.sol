// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { StakingBase } from "../bases/StakingBase.t.sol";

contract StakingParamsTests is StakingBase {

    // Test that we can update base votes
    function testStakingParams__UpdateBaseVotes() public {
        uint256 newBaseVotes = staking.baseVotes() + 1;
        
        vm.prank(address(executor));
        staking.setBaseVotes(newBaseVotes);
        
        assert(staking.baseVotes() == newBaseVotes);
    }

    // Test that we can update stake bonus time.
    function testStakingParams__UpdateStakeBonusTime() public {
        (uint maxStakeBonusTime, uint maxStakeBonusAmount) = staking.stakingSettings();

        vm.prank(address(executor));
        staking.changeStakeTime(uint128(maxStakeBonusTime + 1 weeks));

        (uint newMaxStakeBonusTime, uint newMaxStakeBonusAmount) = staking.stakingSettings();
        assert(newMaxStakeBonusTime == maxStakeBonusTime + 1 weeks);
    }

    // Test that we can update stake bonus amount.
    function testStakingParams__UpdateStakeBonusAmount() public {
        (uint maxStakeBonusTime, uint maxStakeBonusAmount) = staking.stakingSettings();
        
        vm.prank(address(executor));
        staking.changeStakeAmount(uint128(maxStakeBonusAmount + 1));

        (uint newMaxStakeBonusTime, uint newMaxStakeBonusAmount) = staking.stakingSettings();
        assert(newMaxStakeBonusAmount == maxStakeBonusAmount + 1);
    }

    // Test that we can update the Monster Multiplier.
    function testStakingParams__UpdateMonsterMultiplier() public {
        uint256 newMonsterMultiplier = staking.monsterMultiplier() - 25;

        vm.prank(address(executor));
        staking.setMonsterMultiplier(newMonsterMultiplier);
        
        assert(staking.monsterMultiplier() == newMonsterMultiplier);
    }

    // Test that increasing base votes increases rewards for a staked token.
    function testStakingParams__IncreaseBaseVotesIncreasesRewards() public {
        uint originalBaseVotes = staking.baseVotes();

        uint TOKEN_ID_1 = 0;
        address owner1 = mockStakeSingle(TOKEN_ID_1, 0);
        uint o1Power = staking.getTokenVotingPower(TOKEN_ID_1);
        
        uint newBaseVotes = originalBaseVotes + 1;
        vm.prank(address(executor));
        staking.setBaseVotes(newBaseVotes);

        uint TOKEN_ID_2 = 10;
        address owner2 = mockStakeSingle(TOKEN_ID_2, 0);
        uint o2Power = staking.getTokenVotingPower(TOKEN_ID_2);
        assert(o2Power == o1Power + 1);
    }

    // Test that increasing max staked time decreases rewards for the same time commitment.
    function testStakingParams__RewardsDecreaseIfMaxStakedTimeIncreases() public {
        (uint maxStakeBonusTime, uint maxStakeBonusAmount) = staking.stakingSettings();

        uint TOKEN_ID_1 = 0;
        address owner1 = mockStakeSingle(TOKEN_ID_1, block.timestamp + maxStakeBonusTime);
        uint o1Power = staking.getTokenVotingPower(TOKEN_ID_1);
        assert(o1Power == staking.baseVotes() + maxStakeBonusAmount + staking.evilBonus(TOKEN_ID_1));
        
        vm.prank(address(executor));
        staking.changeStakeTime(uint128(maxStakeBonusTime + 1 weeks));

        uint TOKEN_ID_2 = 10;
        address owner2 = mockStakeSingle(TOKEN_ID_2, block.timestamp + maxStakeBonusTime);
        uint o2Power = staking.getTokenVotingPower(TOKEN_ID_2);
        assert(o2Power < o1Power);
    }

    // Test that increasing max staked bonus amount increases rewards for the same time commitment.
    function testStakingParams__RewardsIncreaseIfMaxStakedBonusIncreases() public {
        (uint maxStakeBonusTime, uint maxStakeBonusAmount) = staking.stakingSettings();

        uint TOKEN_ID_1 = 0;
        address owner1 = mockStakeSingle(TOKEN_ID_1, block.timestamp + maxStakeBonusTime);
        uint o1Power = staking.getTokenVotingPower(TOKEN_ID_1);
        assert(o1Power == staking.baseVotes() + maxStakeBonusAmount + staking.evilBonus(TOKEN_ID_1));
        
        vm.prank(address(executor));
        staking.changeStakeAmount(uint128(maxStakeBonusAmount + 10));

        uint TOKEN_ID_2 = 10;
        address owner2 = mockStakeSingle(TOKEN_ID_2, block.timestamp + maxStakeBonusTime);
        uint o2Power = staking.getTokenVotingPower(TOKEN_ID_2);
        assert(o2Power > o1Power);
    }

    // Test that decreasing the Monster Multiplier decreases rewards for monsters, but doesn't impact punks.
    function testStakingParams__DecreaseMonsterMultiplierDecreasesMonsterRewards() public {
        uint originalMonsterMultiplier = staking.monsterMultiplier();

        uint PUNK_1 = 0;
        mockStakeSingle(PUNK_1, 0);
        uint punkPowerBefore = staking.getTokenVotingPower(PUNK_1);

        uint MONSTER_1 = 10000;
        mockStakeSingle(MONSTER_1, 0);
        uint monsterPowerBefore = staking.getTokenVotingPower(MONSTER_1);
        
        uint newMonsterMultiplier = originalMonsterMultiplier - 25;
        vm.prank(address(executor));
        staking.setMonsterMultiplier(newMonsterMultiplier);

        uint PUNK_2 = 10;
        mockStakeSingle(PUNK_2, 0);
        uint punkPowerAfter = staking.getTokenVotingPower(PUNK_2);

        uint MONSTER_2 = 10010;
        address owner2 = mockStakeSingle(MONSTER_2, 0);
        uint monsterPowerAfter = staking.getTokenVotingPower(MONSTER_2);

        assert(punkPowerAfter == punkPowerBefore);
        assert(monsterPowerAfter == monsterPowerBefore / 2);
    }

    // Test that increasing max staked bonus translates to increased voting power.
    function testStakingParams__MaxStakedBonusIncreaseTranslatesToVotingPower() public {
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
}
