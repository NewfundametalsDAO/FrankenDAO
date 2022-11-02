// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { StakingBase } from "../bases/StakingBase.t.sol";

contract StakedSupplyTests is StakingBase {

    // Test that staking FrankenPunk increases staked supply
    function testStakedSupply__StakingFrankenPunkIncreasesStakedSupply() public {
        mockStakeSingle(PUNK_ID);
        assert(staking.stakedFrankenPunks() == 1);
        assert(staking.stakedFrankenMonsters() == 0);
    }

    // Test that unstaking FrankenPunk decreases staked supply
    function testStakedSupply__UnstakingFrankenPunkDecreasesStakedSupply() public {
        address owner = mockStakeSingle(PUNK_ID, 0);
        assert(staking.stakedFrankenPunks() == 1);
        assert(staking.stakedFrankenMonsters() == 0);

        vm.prank(owner);
        mockUnstakeSingle(PUNK_ID);

        assert(staking.stakedFrankenPunks() == 0);
        assert(staking.stakedFrankenMonsters() == 0);
    }

    // Test that staking FrankenMonster increases staked supply
    function testStakedSupply__StakingFrankenMonsterIncreasesStakedSupply() public {
        mockStakeSingle(MONSTER_ID);
        assert(staking.stakedFrankenPunks() == 0);
        assert(staking.stakedFrankenMonsters() == 1);
    }

    // Test that unstaking FrankenMonster decreases staked supply
    function testStakedSupply__UnstakingFrankenMonsterDecreasesStakedSupply() public {
        address owner = mockStakeSingle(MONSTER_ID, 0);
        assert(staking.stakedFrankenPunks() == 0);
        assert(staking.stakedFrankenMonsters() == 1);

        vm.prank(owner);
        mockUnstakeSingle(MONSTER_ID);

        assert(staking.stakedFrankenPunks() == 0);
        assert(staking.stakedFrankenMonsters() == 0);
    }
}
