pragma solidity ^0.8.13;

import { TestBase } from "../TestBase.t.sol";
import { IERC721 } from "../../src/interfaces/IERC721.sol";

contract StakingBase is TestBase {
    IERC721 frankenpunks = IERC721(FRANKENPUNKS);

    function mockStake(uint[] memory ids) public returns (address[] memory) {
        return _mockStake(ids, 0);
    }

    function mockStake(uint[] memory ids, uint stakeTime) public returns (address[] memory) {
        return _mockStake(ids, stakeTime);
    }

    function _mockStake(uint[] memory ids, uint stakeTime) internal returns (address[] memory) {
        address[] memory owners = new address[](ids.length);
        for (uint i; i < ids.length; i++) {
            address owner = frankenpunks.ownerOf(ids[i]);
            vm.prank(owner);
            frankenpunks.approve(address(staking), ids[i]);
            owners[i] = owner;
        }
        staking.stake(ids, stakeTime);
        
        return owners;
    }

    function mockStakeSingle(uint id) public returns (address) {
        return _mockStakeSingle(id, 0);
    }

    function mockStakeSingle(uint id, uint stakeTime) public returns (address) {
        return _mockStakeSingle(id, stakeTime);
    }

    function _mockStakeSingle(uint id, uint stakeTime) public returns (address) {
        address owner = frankenpunks.ownerOf(id);
        vm.startPrank(owner);
        frankenpunks.approve(address(staking), id);

        uint[] memory ids = new uint[](1);
        ids[0] = id;
        staking.stake(ids, stakeTime);

        vm.stopPrank();

        return owner;
    }

    function mockUnstakeSingle(uint id) public returns (address) {
        address owner = staking.ownerOf(id);
        uint[] memory ids = new uint[](1);
        ids[0] = id;
        vm.prank(owner);
        staking.unstake(ids, owner);
    }
   
}
