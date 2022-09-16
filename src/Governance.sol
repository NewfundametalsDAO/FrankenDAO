// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "oz/access/AccessControl.sol";
import "./interfaces/IGovernance.sol";

/// @title FrankenDAO Governance Contract
/// @author Solidity Guild
/// @notice Contract for creating, voting, and executing proposals
abstract contract Governance is AccessControl, IGovernance {
  // State Variables

  // Roles
  bytes32 public constant VETOER = keccak256("Vetoer");

  // Events
  /// @notice Called when an admin or vetoer vetoes a proposal
  /// @param id proposal that has been vetoed
  /// @param vetoer address that vetoed the proposal
  event ProposalVetoed(uint id, address vetoer);

  // @todo - only things to add here is the vetoer logic
  // - Veto ability which allows `veteor` to halt any proposal at any stage unless the proposal is executed.
  //   The `veto(uint proposalId)` logic is a modified version of `cancel(uint proposalId)`
  //   A `vetoed` flag was added to the `Proposal` struct to support this.
  // we'll probably just copy and edit the Compound contracts directly rather than import and edit
  function veto(uint256 proposalId) external {
  //     require(vetoer != address(0), 'NounsDAO::veto: veto power burned');
  //     require(msg.sender == vetoer, 'NounsDAO::veto: only vetoer');
  //     require(state(proposalId) != ProposalState.Executed, 'NounsDAO::veto: cannot veto executed proposal');

  //     Proposal storage proposal = proposals[proposalId];

  //     proposal.vetoed = true;
  //     for (uint256 i = 0; i < proposal.targets.length; i++) {
  //         timelock.cancelTransaction(
  //             proposal.targets[i],
  //             proposal.values[i],
  //             proposal.signatures[i],
  //             proposal.calldatas[i],
  //             proposal.eta
  //         );
  //     }

  //     emit ProposalVetoed(proposalId);
  }
}

