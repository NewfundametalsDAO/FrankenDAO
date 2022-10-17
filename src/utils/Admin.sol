// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../interfaces/IAdmin.sol";
import "../interfaces/IExecutor.sol";

contract Admin is IAdmin {
    /// @notice Founder multisig
    address public founders;

    /// @notice Council multisig
    address public council;

    /// @notice Executor contract address for passed governance proposals
    IExecutor public executor;

    /// @notice Pending administrator addresses for this contract
    address public pendingFounders;
    address public pendingCouncil;

    /// @notice Error thrown for an unauthorized transaction
    error NotAuthorized();

  /////////////////////////////////
  /////////// MODIFIERS ///////////
  /////////////////////////////////

    /// @notice Modifier for function that can only be called by the Executor (Timelock) contract
    modifier onlyExecutor() {
        if(msg.sender != address(executor)) revert Unauthorized();
        _;
    }

    modifier onlyAdmins() {
        if(msg.sender != founders && msg.sender != council) revert Unauthorized();
        _;
    }

    modifier onlyExecutorOrAdmins() {
        if (
            msg.sender != address(executor) && 
            msg.sender != council && 
            msg.sender != founders
        ) revert Unauthorized();
        _;
    }

    /////////////////////////////////
    //////// ADMIN TRANSFERS ////////
    /////////////////////////////////

    /**
     * @notice Begins transfer of founder rights. The newPendingFounders must call `_acceptFounders` to finalize the transfer.
     * @dev Founders function to begin change of founder. The newPendingFounders must call `_acceptFounders` to finalize the transfer.
     * @param _newPendingFounders New pending founder.
     */
    function _setPendingFounders(address _newPendingFounders) external {
        require(msg.sender == founders, "Admin: only founders can set pending founders");
        // Save current value, if any, for inclusion in log
        address oldPendingFounders = pendingFounders;

        // Store pendingFounders with value _newPendingFounders
        pendingFounders = _newPendingFounders;

        // Emit NewPendingFounders(oldPendingFounders, newPendingFounders)
        emit NewPendingFounders(oldPendingFounders, _newPendingFounders);
    }

    /**
     * @notice Accepts transfer of founder rights. msg.sender must be pendingFounders
     * @dev Founders function for pending founder to accept role and update founder
     */
    function _acceptFounders() external {
        // Check caller is pendingFounders and pendingFounders ≠ address(0)
        require(msg.sender == pendingFounders, "FrankenDAO::_acceptFounders: pending founder only");

        // Save current values for inclusion in log
        address oldFounders = founders;
        address oldPendingFounders = pendingFounders;

        // Store founder with value pendingFounders
        founders = pendingFounders;

        // Clear the pending value
        pendingFounders = address(0);

        emit NewFounders(oldFounders, founders);
        emit NewPendingFounders(oldPendingFounders, pendingFounders);
    }

    /**
     * @notice Begins transfer of council rights. The newPendingCouncil must call `_acceptCouncil` to finalize the transfer.
     * @dev Council function to begin change of council. The newPendingCouncil must call `_acceptCouncil` to finalize the transfer.
     * @param _newPendingCouncil New pending council.
     */
    function _setPendingCouncil(address _newPendingCouncil) external onlyAdmins {
        // Save current value, if any, for inclusion in log
        address oldPendingCouncil = pendingCouncil;

        // Store pendingCouncil with value _newPendingCouncil
        pendingCouncil = _newPendingCouncil;

        // Emit NewPendingCouncil(oldPendingCouncil, newPendingCouncil)
        emit NewPendingCouncil(oldPendingCouncil, _newPendingCouncil);
    }

    /**
     * @notice Accepts transfer of council rights. msg.sender must be pendingCouncil
     * @dev Council function for pending council to accept role and update council
     */
    function _acceptCouncil() external {
        // Check caller is pendingCouncil and pendingCouncil ≠ address(0)
        require(msg.sender == pendingCouncil, "FrankenDAO::_acceptCouncil: pending council only");

        // Save current values for inclusion in log
        address oldCouncil = council;
        address oldPendingCouncil = pendingCouncil;

        // Store council with value pendingCouncil
        council = pendingCouncil;

        // Clear the pending value
        pendingCouncil = address(0);

        emit NewCouncil(oldCouncil, council);
        emit NewPendingCouncil(oldPendingCouncil, pendingCouncil);
    }
}

