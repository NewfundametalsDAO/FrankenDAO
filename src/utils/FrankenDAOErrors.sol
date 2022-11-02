// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract FrankenDAOErrors {
    // General purpose.
    error NotAuthorized();

    // Staking
    error NonExistentToken();
    error InvalidDelegation();
    error Paused();
    error InvalidParameter();
    error TokenLocked();

    // Governance
    error AlreadyInitialized();
    error ParameterOutOfBounds();
    error InvalidId();
    error InvalidProposal();
    error InvalidStatus();
    error InvalidInput();
    error AlreadyQueued();
    error AlreadyVoted();
    error RequirementsNotMet();
    error NotEligible();
    error Unauthorized();
    error NotRefundable();
    error InsufficientRefundBalance();
    error DelayNotSatisfied();
    error IdenticalTransactionAlreadyQueued();
    error TransactionNotQueued();
    error TimelockNotMet();
    error StaleTransaction();
    error TransactionReverted();
    error StakedTokensCannotBeTransferred();
}