pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../utils/BaseSetup.sol";
import "./StakingBase.t.sol";

contract StakingTest is StakingBase {

    function testStaking__UnlockTimeCantBeInThePast(uint _id) public {
        vm.assume(_id <= 10_000);
        address owner = frankenpunks.ownerOf(_id);
        vm.startPrank(owner);
        frankenpunks.approve(address(staking), _id);

        uint[] memory ids = new uint[](1);
        ids[0] = _id;

        vm.expectRevert(InvalidParameter.selector);
        staking.stake(ids, block.timestamp - 1 days);
    }

    //// stake frankenpunk
    function testStaking__CanStakeFrankenPunk(uint _id) public {
        vm.assume(_id <= 10_000);
        address owner = mockStakeSingle(_id);

        // staking.ownerOf id 1 should be staker
        assert(staking.ownerOf(_id) == owner);
        // frankenpunk.ownerOf id 1 should be staking
        assert(frankenpunks.ownerOf(_id) == address(staking));
    }

    //// transfer reverts for staked FrankenPunks
    function testStaking__TokensAreNotTransferrable(uint _id) public {
        vm.assume(_id <= 10_000);
        address owner = mockStakeSingle(_id);
        address other = makeAddr("other");

        vm.startPrank(owner);

        //expect revert
        vm.expectRevert("staked tokens cannot be transferred");
        //transfer staked token
        staking.transferFrom(owner, other, _id);
    }

    //// unstake frankenpunk
    function testStaking__UnstakingFrankenPunk(uint _id, uint _unlockTime) public {
        vm.assume(_id <= 10_000);
        vm.assume(_unlockTime > block.timestamp);
        vm.assume(_unlockTime < type(uint128).max);
        // get starting values:
        address owner = frankenpunks.ownerOf(_id);
        uint initialBalance = frankenpunks.balanceOf(owner);

        // stake token:
        mockStakeSingle(_id, _unlockTime);

        vm.warp(_unlockTime + 1);
        vm.startPrank(owner);

        //unstake on staking
        uint[] memory ids = new uint[](1);
        ids[0] = _id;

        staking.unstake(ids, owner);

         //balance on frankenpunk should go back
        assert(frankenpunks.balanceOf(owner) == initialBalance);

        //balance on staking should be zero;
        assert(staking.balanceOf(owner) == 0);

         //frankenpunk.ownerOf id 1 should be staker
        assert(frankenpunks.ownerOf(_id) == owner);
    }
}
