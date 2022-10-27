pragma solidity ^0.8.13;

import { StakingBase } from "./StakingBase.t.sol";
import {IStaking} from "../../src/interfaces/IStaking.sol";

contract GasRefundingTest is StakingBase {
    // set refunding
    function testRefunding__SettingRefund() public {
        dealRefundBalance();
        // Default status is 0 (StakingAndDelegatingRefund)
        uint256 status = uint256(staking.refund());
        assertEq(status, 0);

        // 1 ( StakingRefund )
        setStakingRefundStatus(IStaking.RefundStatus.StakingRefund);

        status = uint256(staking.refund());
        assertEq(status, 1);

        // 2 ( DelegatingRefund )
        setStakingRefundStatus(IStaking.RefundStatus.DelegatingRefund);
        status = uint256(staking.refund());
        assertEq(status, 2);

        // 3 ( NoRefund )
        setStakingRefundStatus(IStaking.RefundStatus.NoRefunds);
        status = uint256(staking.refund());
        assertEq(status, 3);
    }

    // gas refunded for staking
    function testRefunding__RefundingForStaking() public {
        dealRefundBalance();
        setStakingRefundStatus(IStaking.RefundStatus.StakingRefund);

        address owner = frankenpunks.ownerOf(369);
        uint256 initialBalance = owner.balance;
        // get starting balance of addr 1
        vm.startPrank(owner);
        frankenpunks.approve(address(staking), 369);

        // stake tokens
        uint256[] memory ids = new uint256[](1);
        ids[0] = 369;
        staking.stakeWithRefund(ids, block.timestamp + 30 days);

        vm.stopPrank();
        // get new balance
        uint256 newBalance = owner.balance;
        // assert eq starting balance, new balance;
        assertEq(initialBalance, newBalance);
    }

    function testRefunding__StakingRefundRevertsIfPaused() public {
        dealRefundBalance();

        // 3 ( NoRefunds )
        setStakingRefundStatus(IStaking.RefundStatus.NoRefunds);

        address owner = frankenpunks.ownerOf(369);

        vm.startPrank(owner);
        frankenpunks.approve(address(staking), 369);

        uint256[] memory ids = new uint256[](1);
        ids[0] = 369;

        vm.expectRevert(NotRefundable.selector);
        staking.stakeWithRefund(ids, block.timestamp + 30 days);
        vm.stopPrank();

        // 2 DelegatingRefund
        setStakingRefundStatus(IStaking.RefundStatus.DelegatingRefund);

        vm.startPrank(owner);

        vm.expectRevert(NotRefundable.selector);
        staking.stakeWithRefund(ids, block.timestamp + 30 days);

        vm.stopPrank();
    }

    // staking reverts if contract has insufficient balance
    function testRefunding__StakingRefundRevertsIfInsufficientBalance() public {
        address owner = frankenpunks.ownerOf(369);

        vm.startPrank(owner);
        frankenpunks.approve(address(staking), 369);

        uint256[] memory ids = new uint256[](1);
        ids[0] = 369;

        vm.expectRevert(InsufficientRefundBalance.selector);
        staking.stakeWithRefund(ids, block.timestamp + 30 days);

        vm.stopPrank();
    }

    function testRefunding__RefundingForDelegating() public {
        dealRefundBalance();
        setStakingRefundStatus(IStaking.RefundStatus.DelegatingRefund);

        address owner = mockStakeSingle(6251, block.timestamp + 30 days);
        address delegate = frankenpunks.ownerOf(3689);

        //get starting balance of addr 1
        uint256 startingBalance = owner.balance;

        //delegate
        vm.prank(owner);
        staking.delegateWithRefund(delegate);

        //get new balance
        uint256 endingBalance = owner.balance;

        //assert eq starting balance, new balance;
        assertEq(startingBalance, endingBalance);
    }

    // @todo delegating reverts if refunding is paused
    function testRefunding__DelegatingRefundRevertsIfPaused() public {
        dealRefundBalance();

        address owner = mockStakeSingle(1553);
        address delegate = mockStakeSingle(6251);

        setStakingRefundStatus(IStaking.RefundStatus.NoRefunds);

        vm.startPrank(owner);
        vm.expectRevert(NotRefundable.selector);
        staking.delegateWithRefund(delegate);
        vm.stopPrank();

        //2 StakingRefund
        setStakingRefundStatus(IStaking.RefundStatus.StakingRefund);

        vm.startPrank(owner);

        vm.expectRevert(NotRefundable.selector);
        staking.delegateWithRefund(delegate);

        vm.stopPrank();
    }

    // @todo test delegating fails if balance is insufficient
    function testRefunding__DelegatingRefundRevertsIfInsufficientBalance()
        public
    {
        address owner = mockStakeSingle(1553);
        address delegate = mockStakeSingle(6251);

        vm.startPrank(owner);
        vm.expectRevert(InsufficientRefundBalance.selector);
        staking.delegateWithRefund(delegate);
    }
}
