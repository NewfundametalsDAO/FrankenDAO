// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { StakingBase } from "../bases/StakingBase.t.sol";

contract PausedTests is StakingBase {
    address pauser;

    function setUp() override public {
        pauser = makeAddr("pauser");
        super.setUp();
        vm.prank(address(FOUNDER_MULTISIG));
        staking.setPauser(pauser);
    }

    function testPausing__RevertsIfStakingPaused() public {
        vm.prank(pauser);
        staking.setPause(true);

        address owner = frankenpunks.ownerOf(0);
        vm.startPrank(owner);
        frankenpunks.approve(address(staking), 0);

        uint[] memory ids = new uint[](1);
        ids[0] = 0;
        vm.expectRevert(TokenLocked.selector);
        staking.stake(ids, 0);

        vm.stopPrank();
    }

    function testPausing__CanStillDelegateWhilePaused() public {
        address delegator = mockStakeSingle(0);
        address delegatee = mockStakeSingle(10);

        vm.prank(pauser);
        staking.setPause(true);

        vm.prank(delegator);
        staking.delegate(delegatee);

        assert(staking.getDelegate(delegator) == delegatee);
    }

    function testPausing__CanStillUnstakeWhilePaused() public {
        address staker = mockStakeSingle(1559, block.timestamp + 30 days);

        vm.prank(pauser);
        staking.setPause(true);

        vm.warp(block.timestamp + 31 days);

        uint[] memory ids = new uint[](1);
        ids[0] = 1559;
        vm.prank(staker);
        staking.unstake(ids, staker);

        assert(staking.balanceOf(staker) == 0);
    }
}
