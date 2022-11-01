pragma solidity ^0.8.10;

interface IExecutor {

    ////////////////////
    ////// Events //////
    ////////////////////

    /// @notice Emited when a transaction is cancelled
    event CancelTransaction( bytes32 indexed txHash, address indexed target, uint256 value, string signature, bytes data, uint256 eta);
    /// @notice Emited when a transaction is executed
    event ExecuteTransaction( bytes32 indexed txHash, address indexed target, uint256 value, string signature, bytes data, uint256 eta);
    /// @notice Emited when a new delay value is set
    event NewDelay(uint256 indexed newDelay);
    /// @notice Emited when a transaction is queued
    event QueueTransaction( bytes32 indexed txHash, address indexed target, uint256 value, string signature, bytes data, uint256 eta);

    ////////////////////
    ////// Errors //////
    ////////////////////

    /// @notice Error emited when an address isn't authorized to perform an action
    error Unauthorized();
    /// @notice Error emited if a transaction can't be queued yet
    error DelayNotSatisfied();
    /// @notice Error emited if a transaction is already queued
    error IdenticalTransactionAlreadyQueued();
    /// @notice Error emited if a transaction has not been queued
    error TransactionNotQueued();
    /// @notice Error emited if a transaction is attempted before it can be executed
    error TimelockNotMet();
    /// @notice Error emited if a transaction reverts
    error TransactionReverted();

    /////////////////////
    ////// Methods //////
    /////////////////////

    function DELAY() external view returns (uint256);

    function GRACE_PERIOD() external view returns (uint256);

    function cancelTransaction( address target, uint256 value, string memory signature, bytes memory data, uint256 eta) external;

    function executeTransaction( address _target, uint256 _value, string memory _signature, bytes memory _data, uint256 _eta) external returns (bytes memory);

    function queueTransaction( address _target, uint256 _value, string memory _signature, bytes memory _data, uint256 _eta) external returns (bytes32 txHash);

    function queuedTransactions(bytes32) external view returns (bool);
}
