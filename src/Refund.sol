// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Refund {
    event IssueRefund(address refunded, uint256 ammount, bool sent);
    /// @notice The maximum priority fee used to cap gas refunds in `castRefundableVote`
    uint256 public constant MAX_REFUND_PRIORITY_FEE = 2 gwei;

    /// @notice The vote refund gas overhead, including 7K for ETH transfer and 29K for general transaction overhead
    uint256 public constant REFUND_BASE_GAS = 36000;

    function _refundGas(uint256 startGas) internal {
        unchecked {
            uint256 balance = address(this).balance;
            if (balance == 0) {
                return;
            }
            uint256 gasPrice = min(tx.gasprice, block.basefee + MAX_REFUND_PRIORITY_FEE);
            uint256 gasUsed = startGas - gasleft() + REFUND_BASE_GAS;
            uint256 refundAmount = min(gasPrice * gasUsed, balance);
            (bool refundSent, ) = msg.sender.call{ value: refundAmount }('');
            emit IssueRefund(msg.sender, refundAmount, refundSent);
        }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
