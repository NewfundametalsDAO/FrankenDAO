// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../interfaces/IRefundable.sol";

/// @notice Provides a refundable modifier that can be used for inhering contracts to refund user gas cost
/// @dev This functionality is inherited by Governance.sol (for proposing and voting) and Staking.sol (for staking and delegating)
contract Refundable is IRefundable {
    /// @notice The maximum priority fee used to cap gas refunds
    uint256 public constant MAX_REFUND_PRIORITY_FEE = 2 gwei;

    /// @notice The vote refund gas overhead, including 7K for ETH transfer and 29K for general transaction overhead
    // @todo is this right or just copied from nouns? make sure it doesn't overpay!
    uint256 public constant REFUND_BASE_GAS = 36000;

    /// @notice Take the amount spent on gas supplied and send that to msg.sender from the contract's balance
    /// @param _startGas Amount of gas to refund
    /// @dev Lifted straight from NounsDAO: https://github.com/nounsDAO/nouns-monorepo/blob/master/packages/nouns-contracts/contracts/governance/NounsDAOLogicV2.sol#L1033-L1046
    function _refundGas(uint256 _startGas) internal {
        unchecked {
            uint256 balance = address(this).balance;
            if (balance == 0) {
                return;
            }
            uint256 gasPrice = min(tx.gasprice, block.basefee + MAX_REFUND_PRIORITY_FEE);
            uint256 gasUsed = _startGas - gasleft() + REFUND_BASE_GAS;

            if (gasPrice * gasUsed > balance) revert InsufficientRefundBalance();

            uint refundAmount = gasPrice * gasUsed;

            // There shouldn't be any reentrancy risk, as this is always called last in all contracts.
            (bool refundSent, ) = msg.sender.call{ value: refundAmount }('');
            emit IssueRefund(msg.sender, refundAmount, refundSent);
        }
    }

    /// @notice Returns the lower value of two uints
    /// @param a First uint
    /// @param b Second uint
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
