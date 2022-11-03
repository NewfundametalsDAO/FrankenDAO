// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { StakingBase } from "../bases/StakingBase.t.sol";

contract StakingTests is StakingBase {

    // Test that you can't stake a token with an unlock time in the past.
    function testStaking__UnlockTimeCantBeInThePast() public {
        address owner = frankenpunks.ownerOf(PUNK_ID);

        vm.startPrank(owner);
        frankenpunks.approve(address(staking), PUNK_ID);

        uint[] memory ids = new uint[](1);
        ids[0] = PUNK_ID;

        vm.expectRevert(InvalidParameter.selector);
        staking.stake(ids, block.timestamp - 1 days);
    }

    // Test that staking a FrankenPunk works as expected.
    function testStaking__CanStakeFrankenPunk() public {
        address owner = mockStakeSingle(PUNK_ID);

        assert(staking.ownerOf(PUNK_ID) == owner);

        assert(frankenpunks.ownerOf(PUNK_ID) == address(staking));
    }

    // Test that unstaking works as expected.
    function testStaking__UnstakingFrankenPunk() public {
        (uint128 maxStakeBonusTime, ) = staking.stakingSettings();

        address owner = frankenpunks.ownerOf(PUNK_ID);
        uint initialBalance = frankenpunks.balanceOf(owner);

        mockStakeSingle(PUNK_ID, block.timestamp + 30 days);

        vm.warp(block.timestamp + 31 days);

        uint[] memory ids = new uint[](1);
        ids[0] = PUNK_ID;

        vm.prank(owner);
        staking.unstake(ids, owner);

        assert(frankenpunks.balanceOf(owner) == initialBalance);
        assert(staking.balanceOf(owner) == 0);
        assert(frankenpunks.ownerOf(PUNK_ID) == owner);
    }

    // Test that user can unstake immediately if stake time is set to zero.
    function testStaking__UnstakingImmediately() public {
        address owner = mockStakeSingle(PUNK_ID);

        uint[] memory ids = new uint[](1);
        ids[0] = PUNK_ID;

        vm.prank(owner);
        staking.unstake(ids, owner);

        assert(frankenpunks.ownerOf(PUNK_ID) == owner);
    }
}
