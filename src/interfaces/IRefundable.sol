// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

abstract contract IRefundable {
    /// @notice Error thrown when the contract balance is too low to refund gas
    error InsufficientRefundBalance();

    /// @notice Emitted when a refund is issued
    event IssueRefund(address refunded, uint256 amount, bool sent);
}