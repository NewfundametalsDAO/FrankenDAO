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
        mockStakeSingle(200);

        assertEq(
            staking.stakedFrankenPunks(),
            1
        );

        mockUnstakeSingle(200);

        assertEq(
            staking.stakedFrankenPunks(),
            0
        );
    }

    // @todo Staking FrankenMonster increases staked supply
    // @todo Unstaking FrankenPunk decreases staked supply
}
