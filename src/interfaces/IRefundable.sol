pragma solidity ^0.8.10;

interface IRefundable {

    ////////////////////
    ////// Events //////
    ////////////////////

    /// @notice Emitted when a refund is issued
    event IssueRefund(address refunded, uint256 amount, bool sent);

    /////////////////////
    ////// Methods //////
    /////////////////////

    function MAX_REFUND_PRIORITY_FEE() external view returns (uint256);
    function REFUND_BASE_GAS() external view returns (uint256);
}
