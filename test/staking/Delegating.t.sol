pragma solidity ^0.8.13;

import "./StakingBase.t.sol";

contract DelegatingTest is StakingBase {
    // delegate - get my address if I haven't delegated
    function testDelegating__DelegateToSelfByDefault(uint _id) public {
        vm.assume(_id < 10_000);
         //addr 1 stakes
         address owner = mockStakeSingle(_id);
         //get current delegate of addr 1
         assertEq(
            staking.getDelegate(owner),
            owner
         );
    }

    // delegate - get delegate address if I have delegated
    function testDelegating__GetDelegateAddress(uint _idOne, uint _idTwo) public {
        vm.assume(_idOne < 10_000 && _idTwo < 10_000);

        // addr 1 stakes
        address owner = mockStakeSingle(_idOne);
        address delegate = frankenpunks.ownerOf(_idTwo);

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

    function testDelegating__RevertsIfDelegatingToCurrentDelegate(uint _idOne, uint _idTwo) public {
        vm.assume(_idOne < 10_000 && _idTwo < 10_000);

        // addr 1 stakes
        address owner = mockStakeSingle(_idOne);
        address delegate = frankenpunks.ownerOf(_idTwo);

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

    function testDelegating__RevertsIfAddressHasNotStaked(uint _idOne, uint _idTwo) public {
        vm.assume(_idOne < 10_000 && _idTwo < 10_000);

        address owner = frankenpunks.ownerOf(_idOne);
        address delegate = mockStakeSingle(_idTwo);

        vm.startPrank(owner);

        // address that hasn't staked tries to delegate
        vm.expectRevert(InvalidDelegation.selector);
        staking.delegate(
            delegate
        );
    }

}
