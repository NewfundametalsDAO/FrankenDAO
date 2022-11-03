// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { StakingBase } from "../bases/StakingBase.t.sol";

contract DelegatingTests is StakingBase {
    
    // Test that a staked token is delegated to self by default. 
    function testDelegating__DelegateToSelfByDefault() public {
         address owner = mockStakeSingle(PUNK_ID);
         assert(staking.getDelegate(owner) == owner);
    }

    // Test that delegating to other staked user works.
    function testDelegating__GetDelegateAddress() public {
        address owner = mockStakeSingle(PUNK_ID);
        address delegate = mockStakeSingle(MONSTER_ID);

        vm.prank(owner);
        staking.delegate(delegate);

        assert(staking.getDelegate(owner) == delegate);
    }

    // Test that delegating to a non-staked user works.
    function testDelegating__DelegateToNonStakedUser() public {
        address owner = mockStakeSingle(PUNK_ID);
        address delegate = makeAddr("unstakedDelegate");

        vm.prank(owner);
        staking.delegate(delegate);

        assert(staking.getDelegate(owner) == delegate);
    }

    // Test that you cannot delegate to your current delegate.
    function testDelegating__RevertsIfDelegatingToCurrentDelegate() public {
        address owner = mockStakeSingle(PUNK_ID);
        address delegate = makeAddr("unstakedDelegate");

        vm.prank(owner);
        staking.delegate(delegate);

        vm.expectRevert(InvalidDelegation.selector);
        staking.delegate(delegate);
    }

    // Test that you cannot delegate if you haven't staked.
    function testDelegating__RevertsIfAddressHasNotStaked() public {
        address owner = frankenpunks.ownerOf(PUNK_ID);
        address delegate = makeAddr("unstakedDelegate");

        vm.prank(owner);
        vm.expectRevert(InvalidDelegation.selector);
        staking.delegate(delegate);
    }
}
