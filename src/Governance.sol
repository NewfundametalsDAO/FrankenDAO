// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "oz/access/AccessControl.sol";
import "./base/compound-bravo/GovernorBravoDelegate.sol";
import "./base/compound-bravo/GovernorBravoDelegator.sol";
import "./base/compound-bravo/GovernorBravoInterfaces.sol";

/// @title FrankenDAO Governance Contract
/// @author Solidity Guild
/// @notice Contract for creating, voting, and executing proposals
abstract contract Governance is AccessControl, GovernorBravoDelegateStorageV1, GovernorBravoEvents {
  // State Variables

  // Roles
  bytes32 public constant VETOER = keccak256("Vetoer");

  // Events
  /// @notice Called when an admin or vetoer vetoes a proposal
  /// @param id proposal that has been vetoed
  /// @param vetoer address that vetoed the proposal
  event ProposalVetoed(uint id, address vetoer);

  // TODO: veto proposal
  function calculateVotingPower(address voter) external virtual returns (uint votingPower); 
}

