pragma solidity ^0.8.13;

import { IGovernance } from "../../src/interfaces/IGovernance.sol";
import { GovernanceBase } from "../governance/GovernanceBase.t.sol";

contract Cancel is GovernanceBase {
    // user can cancel their own
    function testGovCancel__UserCanCancelOwnProposal() public {
        uint proposalId = _createProposal();
        assert(_checkState(proposalId, IGovernance.ProposalState.Pending));

        vm.prank(proposer);
        gov.cancel(proposalId);

        assert(_checkState(proposalId, IGovernance.ProposalState.Canceled));
    }

    // Test that a proposal cannot be canceled twice.
    function testGovCancel__ProposalCannotBeCanceledTwice() public {
        uint proposalId = _createProposal();
        assert(_checkState(proposalId, IGovernance.ProposalState.Pending));

        vm.startPrank(proposer);
        gov.cancel(proposalId);

        assert(_checkState(proposalId, IGovernance.ProposalState.Canceled));

        vm.expectRevert(InvalidStatus.selector);
        gov.cancel(proposalId);
    }

    function testGovCancel__NobodyCanCancelUnlessThingsChange() public {
        uint proposalId = _createProposal();
        assert(_checkState(proposalId, IGovernance.ProposalState.Pending));

        vm.prank(voter);
        vm.expectRevert(NotEligible.selector);
        gov.cancel(proposalId);
    }

    // other can cancel if they fall below (@todo NOT POSSIBLE, so doesn't matter!)
    // function testGovCancel__AnyoneCanCancelProposalIfProposerPowerFalls() public {
    //     (address[] memory targets, uint[] memory values, string[] memory sigs, bytes[] memory calldatas) = _generateFakeProposalData();

    //     vm.prank(proposer);
    //     uint proposalId = gov.propose(targets, values, sigs, calldatas, "test");
    //     IGovernance.ProposalState proposalState = gov.state(proposalId);
    //     assert(proposalState == IGovernance.ProposalState.Pending);

    //     mockUnstakeSingle(PROPOSER_TOKEN_ID);

    //     vm.prank(voter);
    //     gov.cancel(proposalId);
    //     proposalState = gov.state(proposalId);
    //     assert(proposalState == IGovernance.ProposalState.Canceled);
    // }


    // user can cancel after voting starts

    // cancelling can happen after queued and it's not in executor (and cancels exec as well)
}