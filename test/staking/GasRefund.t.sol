pragma solidity ^0.8.13;

import { StakingBase } from "./StakingBase.t.sol";

contract GasRefundingTest is StakingBase {
    // set refunding
    function testRefunding__SettingRefund() public {
        dealRefundBalance();
        // Default status is 0 (NoRefund)
        uint256 status = uint256(staking.refund());
        assertEq(status, 0);

        // 1 ( StakingRefund )
        setRefundStatus(1);

        status = uint256(staking.refund());
        assertEq(status, 1);

        // 2 ( DelegatingRefund )
        setRefundStatus(2);
        status = uint256(staking.refund());
        assertEq(status, 2);

        // 3 ( StakingAndDelegatingRefund )
        setRefundStatus(3);
        status = uint256(staking.refund());
        assertEq(status, 3);
    }

    // gas refunded for staking
    function testRefunding__RefundingForStaking(uint256 _id) public {
        vm.assume(_id < 10_000);

        dealRefundBalance();
        setRefundStatus(1);

        address owner = frankenpunks.ownerOf(_id);
        uint256 initialBalance = owner.balance;
        // get starting balance of addr 1
        vm.startPrank(owner);
        frankenpunks.approve(address(staking), _id);

        // stake tokens
        uint256[] memory ids = new uint256[](1);
        ids[0] = _id;
        staking.stakeWithRefund(ids, block.timestamp + 30 days);

        vm.stopPrank();
        // get new balance
        uint256 newBalance = owner.balance;
        // assert eq starting balance, new balance;
        assertEq(initialBalance, newBalance);
    }

    function testRefunding__StakingRefundRevertsIfPaused(uint256 _id) public {
        vm.assume(_id < 10_000);
        dealRefundBalance();

        address owner = frankenpunks.ownerOf(_id);

        vm.startPrank(owner);
        frankenpunks.approve(address(staking), _id);

        uint256[] memory ids = new uint256[](1);
        ids[0] = _id;

        // reverts by default (NoRefund)
        vm.expectRevert(NotRefundable.selector);
        staking.stakeWithRefund(ids, block.timestamp + 30 days);
        vm.stopPrank();

        // 2 DelegatingRefund
        setRefundStatus(2);

        vm.startPrank(owner);

        vm.expectRevert(NotRefundable.selector);
        staking.stakeWithRefund(ids, block.timestamp + 30 days);

        vm.stopPrank();
    }

    // staking reverts if contract has insufficient balance
    function testRefunding__StakingRefundRevertsIfInsufficientBalance(
        uint256 _id
    ) public {
        vm.assume(_id < 10_000);

        address owner = frankenpunks.ownerOf(_id);

        vm.startPrank(owner);
        frankenpunks.approve(address(staking), _id);

        uint256[] memory ids = new uint256[](1);
        ids[0] = _id;

        vm.expectRevert(InsufficientRefundBalance.selector);
        staking.stakeWithRefund(ids, block.timestamp + 30 days);

        vm.stopPrank();
    }

    // @todo gas refunded for delegating
    //function testRefunding__RefundingForDelegating(
    //uint256 _idOne,
    //uint256 _idTwo
    //) public {
    //vm.assume(_idOne > 0 && _idTwo > 0);
    //vm.assume(_idOne < 10_000 && _idTwo < 10_000);
    //vm.assume(frankenpunks.ownerOf(_idOne) != frankenpunks.ownerOf(_idTwo));

    //setRefundStatus(2);

    //address owner = mockStakeSingle(_idOne, block.timestamp + 30 days);

    ////get starting balance of addr 1
    //uint256 startingBalance = owner.balance;

    ////delegate
    //vm.prank(owner);
    //staking.delegateWithRefund(frankenpunks.ownerOf(_idTwo));

    ////get new balance
    //uint256 endingBalance = owner.balance;

    ////assert eq starting balance, new balance;
    //assertEq(startingBalance, endingBalance);
    //}

    // @todo delegating reverts if refunding is paused
    //function testRefunding__DelegatingRefundRevertsIfPaused() public { }

    // @todo test delegating fails if balance is insufficient
    //function testRefunding__DelegatingRefundRevertsIfInsufficientBalance() public {}
}
