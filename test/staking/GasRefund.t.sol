// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { StakingBase } from "../bases/StakingBase.t.sol";

contract GasRefundingTest is StakingBase {
    uint TOKEN_ID = 369;

    // Test that gas refunding works for staking
    function testRefunding__RefundingForStaking() public {
        vm.deal(address(staking), 5 ether);

        uint256[] memory ids = new uint256[](1);
        ids[0] = TOKEN_ID;

        address owner = frankenpunks.ownerOf(TOKEN_ID);
        uint256 initialBalance = owner.balance;

        vm.startPrank(owner);
        frankenpunks.approve(address(staking), TOKEN_ID);
        staking.stake(ids, block.timestamp + 30 days);
        vm.stopPrank();

        assert(initialBalance == owner.balance);
    }

    // // Test that gas refunding works for delegating.
    // function testRefunding__RefundingForDelegating() public {
    //     vm.deal(address(staking), 5 ether);

    //     uint256[] memory ids = new uint256[](1);
    //     ids[0] = TOKEN_ID;

    //     address owner = frankenpunks.ownerOf(TOKEN_ID);
    //     uint256 initialBalance = owner.balance;

    //     vm.startPrank(owner);
    //     frankenpunks.approve(address(staking), TOKEN_ID);
    //     staking.delegate(ids, block.timestamp + 30 days);
    //     vm.stopPrank();

    //     assert(initialBalance == owner.balance);
    // }

    // // Test that gas refunding reverts with correct error if no balance.
    // function testRefunding__RevertsIfNoBalance() public {
    //     uint256[] memory ids = new uint256[](1);
    //     ids[0] = TOKEN_ID;

    //     address owner = frankenpunks.ownerOf(TOKEN_ID);

    //     vm.startPrank(owner);
    //     frankenpunks.approve(address(staking), TOKEN_ID);
    //     // vm.expectRevert(InsufficientRefundBalance.selector);
    //     staking.stake(ids, 0);
    //     vm.stopPrank();
    // }

    // // Test that staking doesn't refund but works if stakingRefund is off.
    // function testRefunding__StakingRefundOff() public {
    //     vm.deal(address(staking), 5 ether);

    //     uint256[] memory ids = new uint256[](1);
    //     ids[0] = TOKEN_ID;

    //     address owner = frankenpunks.ownerOf(TOKEN_ID);
    //     uint256 initialBalance = owner.balance;

    //     vm.startPrank(owner);
    //     frankenpunks.approve(address(staking), TOKEN_ID);
    //     staking.stake(ids, block.timestamp + 30 days);
    //     vm.stopPrank();

    //     assert(initialBalance < owner.balance);
    // }

    // // Test that delegating doesn't refund but works if delegatingRefund is off.
    // function testRefunding__DelegatingRefundOff() public {
    //     vm.deal(address(staking), 5 ether);

    //     uint256[] memory ids = new uint256[](1);
    //     ids[0] = TOKEN_ID;

    //     address owner = frankenpunks.ownerOf(TOKEN_ID);
    //     uint256 initialBalance = owner.balance;

    //     vm.startPrank(owner);
    //     frankenpunks.approve(address(staking), TOKEN_ID);
    //     staking.delegate(ids, block.timestamp + 30 days);
    //     vm.stopPrank();

    //     assert(initialBalance < owner.balance);
    // }
}
