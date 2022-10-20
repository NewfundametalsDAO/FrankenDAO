pragma solidity ^0.8.13;

import { TestBase } from "../TestBase.t.sol";
import { IERC721 } from "../../src/interfaces/IERC721.sol";

contract StakingBase is TestBase {
    IERC721 frankenpunks = IERC721(FRANKENPUNKS);

    function mockStake(uint[] memory ids) public returns (address[] memory) {
        address[] memory owners = new address[](ids.length);
        for (uint i; i < ids.length; i++) {
            address owner = frankenpunks.ownerOf(ids[i]);
            vm.prank(owner);
            frankenpunks.approve(address(staking), ids[i]);
            owners[i] = owner;
        }
        staking.stake(ids, 0);
        
        return owners;
    }

    function mockStakeSingle(uint id) public returns (address) {
        address owner = frankenpunks.ownerOf(id);
        vm.startPrank(owner);
        frankenpunks.approve(address(staking), id);
        
        uint[] memory ids = new uint[](1);
        ids[0] = id;
        staking.stake(ids, 0);
        
        vm.stopPrank();
        
        return owner;
    }
   
}