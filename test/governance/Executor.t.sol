// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { GovernanceBase } from "../bases/GovernanceBase.t.sol";
import { IGovernance } from "../../src/interfaces/IGovernance.sol";

contract ExecutorTests is GovernanceBase {
    // Test that the same tx hash can't be queued twice.
    function testExecutor__CantQueueIdenticalTxHashTwice() public {
        uint proposalId = _createSuccessfulProposal();
        uint proposalId2 = _createSuccessfulProposal();

        gov.queue(proposalId);

        vm.expectRevert(IdenticalTransactionAlreadyQueued.selector);
        gov.queue(proposalId2);
    }

    // Test that successful proposals revert if executed before delay.
    function testExecutor__RevertsBeforeDelay() public {
        uint proposalId = _createSuccessfulProposal();
        gov.queue(proposalId);

        vm.expectRevert(TimelockNotMet.selector);
        gov.execute(proposalId);
    }

    // Test that successful proposals revert if not executed in grace period.
    function testExecutor__RevertsAfterGracePeriod() public {
        uint proposalId = _createSuccessfulProposal();
        gov.queue(proposalId);
        vm.warp(block.timestamp + executor.DELAY() + executor.GRACE_PERIOD() + 1);

        vm.expectRevert(InvalidStatus.selector);
        gov.execute(proposalId);
    }

    // Test that executing works with no sig and only calldata.
    function testExecutor__ExecuteNoSigCalldata() public {
        uint proposalId = _passCustomProposal("", abi.encodeWithSignature("setVotingPeriod(uint256)", 2 days));
        gov.queue(proposalId);
        vm.warp(block.timestamp + executor.DELAY() + 1);
        gov.execute(proposalId);

        assert(gov.votingPeriod() == 2 days);
    }

    // Test that executing reverts if the tx reverts.
    function testExecutor__ExecuteRevertsIfTxReverts() public {
        uint proposalId = _passCustomProposal("setVotingPeriod(uint256)", abi.encode(2));
        gov.queue(proposalId);
        vm.warp(block.timestamp + executor.DELAY() + 1);

        vm.expectRevert(TransactionReverted.selector);
        gov.execute(proposalId);
    }

    // Test that Executor can execute a proposal with Ether value.
    function testExecutor__ExecutionSucceedsWithEtherValue() public {
        vm.deal(address(executor), 100 ether);
        uint proposalId = _passCustomProposal(100 ether, "", bytes(""));

        uint govBalBefore = address(gov).balance;

        gov.queue(proposalId);
        vm.warp(block.timestamp + executor.DELAY());
        gov.execute(proposalId);

        assert(address(gov).balance - govBalBefore == 100 ether);
    }
}
