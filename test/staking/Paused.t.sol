pragma solidity ^0.8.13;

import "../../src/Staking.sol";
import { StakingBase } from "./StakingBase.t.sol";

contract PausedTest is StakingBase {
    function testPausing__RevertsIfStakingPaused() public {
        vm.prank(address(FOUNDER_MULTISIG));
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

        vm.prank(address(FOUNDER_MULTISIG));
        staking.setPause(true);

        vm.prank(delegator);
        staking.delegate(delegatee);

        assert(staking.getDelegate(delegator) == delegatee);
    }

    function testPausing__CanStillUnstakeWhilePaused() public {
        emit log_named_uint("timestamp", block.timestamp);
        // 1. Stake tokens
        address staker = mockStakeSingle(1559, block.timestamp + 30 days);
        // 2. Pause Staking
        vm.prank(address(FOUNDER_MULTISIG));
        staking.setPause(true);
        // 3. Warp forward to unstake time
        vm.warp(block.timestamp + 31 days);
        emit log_named_uint("timestamp", block.timestamp);
        // 4. Unstake tokens
        uint[] memory ids = new uint[](1);
        ids[0] = 1559;
        vm.prank(staker);
        staking.unstake(ids, staker);
        // 5. Balance of staked tokens should be 0
        assert(staking.balanceOf(staker) == 0);
    }
}
