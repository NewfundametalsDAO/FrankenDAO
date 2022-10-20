pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../utils/BaseSetup.sol";

error NonExistentToken();
error InvalidDelegation();
error Paused();
error InvalidParameter();
error TokenLocked();
error ZeroAddress();

contract StakingTest is Test, BaseSetup {
    address staker;

    uint256[] public ids;

    function setUp() public {
        staker = makeAddr("staker");

        ids.push(frankenpunk.mint(staker));
        ids.push(frankenpunk.mint(staker));

        for (uint256 index = 0; index < ids.length; index++) {
            vm.prank(staker);
            frankenpunk.approve(address(staking), ids[index]);
        }
    }

    function testThisWorks() public {
        uint256 balance = frankenpunk.balanceOf(staker);
        assertEq(balance, ids.length);
    }

    function stakeTokens(uint256 _unlockTime) internal {

        staking.stake(ids, _unlockTime);
    }

    function unstakeTokens() internal {
        staking.unstake(ids, staker);
    }

    function testUnlockTimeCantBeInThePast() public {
        vm.warp(1 weeks);

        vm.startPrank(staker);
        vm.expectRevert(InvalidParameter.selector);
        stakeTokens(block.timestamp - 1 days);
    }

    function testStakingNoTokensFails() public {
        vm.warp(1 weeks);

        ids.pop();
        ids.pop();

        vm.startPrank(staker);

        vm.expectRevert(InvalidParameter.selector);
        staking.stake(ids, block.timestamp + 30 days);
    }

    // stake frankenpunk
    function testStakingFrankenPunk() public {
        vm.warp(1 weeks);

        vm.startPrank(staker);
        stakeTokens(block.timestamp + 30 days);

        // staker frankenpunk.balanceOf should equal 0
        assert(frankenpunk.balanceOf(staker) == 0);
        // staking frankenpunk.balanceOf should equal 1
        assert(frankenpunk.balanceOf(address(staking)) == ids.length);
        // staking.ownerOf id 1 should be staker
        assert(staking.ownerOf(ids[0]) == staker);
        // frankenpunk.ownerOf id 1 should be staking
        assert(frankenpunk.ownerOf(ids[0]) == address(staking));
    }

    // transfer reverts for staked FrankenPunks
    function testStakedTokensAreNotTransferrable() public {
        address other = makeAddr("other");
        vm.warp(1 weeks);

        vm.startPrank(staker);
        stakeTokens(block.timestamp + 30 days);

        //expect revert
        vm.expectRevert("staked tokens cannot be transferred");
        //transfer staked token
        staking.transferFrom(staker, other, ids[0]);
    }

    // unstake frankenpunk
    function testUnstakingFrankenPunk() public {
        vm.warp(1 weeks);

        vm.startPrank(staker);
        stakeTokens(block.timestamp + 30 days);

        // @todo 31 days should work here but throws TokenLocked()
        // (meaning the staking lock isn't up yet)
        vm.warp(37 days);

        //unstake on staking
        unstakeTokens();

        // balance on frankenpunk should go back
        assert(frankenpunk.balanceOf(staker) == ids.length);

        //balance on staking should be zero;
        assert(staking.balanceOf(staker) == 0);

        // frankenpunk.ownerOf id 1 should be staker
        assert(frankenpunk.ownerOf(ids[0]) == staker);
    }

    function pauseStaking() internal {
        staking.setPause(true);
    }

    function unPauseStaking() internal {
        staking.setPause(false);
    }

    function testPausingAndUnpausingStaking() public {
        vm.startPrank(founders);
        // pause staking
        pauseStaking();

        //check for staking paused variable on staking
        assert(staking.paused());

        //unpause staking;
        unPauseStaking();
        //for staking paused variable on staking;
        assert(staking.paused() == false);
    }

    function testStakingRevertsWhenPaused() public {
        //pause staking
        vm.prank(founders);
        pauseStaking();
        vm.stopPrank();
        //try to stake frankenpunk on staking

        vm.startPrank(staker);
        vm.expectRevert(TokenLocked.selector);
        stakeTokens(block.timestamp + 30 days);
    }

    // revert unstaking if paused
    function testUnstakingRevertsWhenPaused() public {
        //try to stake frankenpunk on staking
        vm.startPrank(staker);
        stakeTokens(block.timestamp + 30 days);
        vm.stopPrank();

        //pause staking
        vm.prank(founders);
        pauseStaking();
        vm.stopPrank();

        //expert revert;
        vm.expectRevert(TokenLocked.selector);
        //try to unstake frankenpunk from staking;
        unstakeTokens();
    }
}
