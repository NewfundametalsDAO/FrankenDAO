pragma solidity ^0.8.13;

import "../../src/Staking.sol";
import "../utils/mocks/Token.sol";

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

    // @todo make sure this is the right test, asked in discord
    function testPausing__CanStillUnstakeWhilePaused() public {
        address staker = mockStakeSingle(0);

        vm.prank(address(FOUNDER_MULTISIG));
        staking.setPause(true);

        uint[] memory ids = new uint[](1);
        ids[0] = 0;
        vm.prank(staker);
        staking.unstake(ids, staker);

        assert(staking.balanceOf(staker) == 0);
    }
}
