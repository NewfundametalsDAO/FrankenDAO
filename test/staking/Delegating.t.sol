// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { StakingBase } from "../bases/StakingBase.t.sol";

contract DelegatingTests is StakingBase {
    uint[] ids = [1553, 8687];
    // delegate - get my address if I haven't delegated
    function testDelegating__DelegateToSelfByDefault() public {
         //addr 1 stakes
         address owner = mockStakeSingle(ids[0]);
         //get current delegate of addr 1
         assertEq(
            staking.getDelegate(owner),
            owner
         );
    }

    // delegate - get delegate address if I have delegated
    function testDelegating__GetDelegateAddress() public {

        // addr 1 stakes
        address owner = mockStakeSingle(ids[0]);
        address delegate = frankenpunks.ownerOf(ids[1]);

        vm.startPrank(owner);

        // delegate
        staking.delegate(
            delegate
        );

        assertEq(
            staking.getDelegate(owner),
            delegate
        );
    }

    function testDelegating__RevertsIfDelegatingToCurrentDelegate() public {

        // addr 1 stakes
        address owner = mockStakeSingle(ids[0]);
        address delegate = frankenpunks.ownerOf(ids[1]);

        // delegate
        vm.startPrank(owner);
        staking.delegate(
            delegate
        );

        // try to delegate to the same address again
        vm.expectRevert(InvalidDelegation.selector);
        staking.delegate(
            delegate
        );
    }

    function testDelegating__RevertsIfAddressHasNotStaked() public {
        address owner = frankenpunks.ownerOf(ids[0]);
        address delegate = mockStakeSingle(ids[1]);

        vm.startPrank(owner);

        // address that hasn't staked tries to delegate
        vm.expectRevert(InvalidDelegation.selector);
        staking.delegate(
            delegate
        );
    }
}
