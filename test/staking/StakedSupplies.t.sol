pragma solidity ^0.8.13;

import { StakingBase } from "./StakingBase.t.sol";

contract StakedSupplyTest is StakingBase {

    // Staking FrankenPunk increases staked supply
    function testStakedSupply__StakingFrankenPunkIncreasesStakedSupply()
    public {
        mockStakeSingle(200);

        assertEq(
            staking.stakedFrankenPunks(),
            1
        );
    }

    // Unstaking FrankenPunk decreases staked supply
    function testStakedSupply__UnstakingFrankenPunkDecreasesStakedSupply()
    public {
        uint _id = 200;
        mockStakeSingle(_id, block.timestamp + 30 days);

        assertEq(
            staking.stakedFrankenPunks(),
            1
        );

        vm.warp(block.timestamp + 31 days);
        mockUnstakeSingle(_id);

        assertEq(
            staking.stakedFrankenPunks(),
            0
        );
    }

    // @todo Staking FrankenMonster increases staked supply
    // @todo Unstaking FrankenMonster decreases staked supply
}
