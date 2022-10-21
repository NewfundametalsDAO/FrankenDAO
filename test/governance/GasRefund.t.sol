pragma solidity ^0.8.13;

import { GovernanceBase } from "./GovernanceBase.t.sol";
import { IGovernance } from "../../src/interfaces/IGovernance.sol";
import "forge-std/Test.sol";

contract GasRefundTests is GovernanceBase {
    // Test that executor can turn off gas refunds.
    function testGovGasRefund__ExecutorCanTurnOffGasRefunds() public {
        ( 
            address[] memory targets, 
            uint[] memory values, 
            string[] memory sigs, 
            bytes[] memory calldatas
        ) = _generateFakeProposalData();

        sigs[0] = "setRefund(uint8)";
        calldatas[0] = abi.encode(IGovernance.RefundStatus.VotingAndProposalRefund);

        vm.prank(proposer);
        uint proposalId = gov.propose(targets, values, sigs, calldatas, "test");
        vm.prank(COUNCIL_MULTISIG);
        gov.verifyProposal(proposalId);

        // @todo switch this to warp when switching to times
        vm.roll(block.number + gov.votingDelay());

        _vote(proposalId, 1, true); // voter votes for proposal

        // @todo switch this to warp when switching to times
        vm.roll(block.number + gov.votingPeriod() + 1);

        gov.queue(proposalId);

        vm.warp(block.timestamp + executor.DELAY());

        IGovernance.RefundStatus refund = gov.refund();
        assert(refund == IGovernance.RefundStatus.NoRefunds);

        gov.execute(proposalId);

        IGovernance.RefundStatus newRefund = gov.refund();
        assert(newRefund == IGovernance.RefundStatus.VotingAndProposalRefund);
    }
}
// reverts if insufficient balance: voting
// reverts if insufficient balance: proposing
// reverts if refunding is turned off: voting
// reverts if refunding is turned off: proposing
// refunds gas for voting
// refund gas for proposing
// only admin can turn on refunding for voting
// only admin can turn on refunding for proposing
// proposal (executor) can turn on refunding

