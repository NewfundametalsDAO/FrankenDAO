pragma solidity ^0.8.13;

interface IExecutor {
    event NewDelay(uint256 indexed newDelay);
    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint256 value, string signature, bytes data, uint256 eta);
    event ExecuteTransaction( bytes32 indexed txHash, address indexed target, uint256 value, string signature, bytes data, uint256 eta);
    event QueueTransaction( bytes32 indexed txHash, address indexed target, uint256 value, string signature, bytes data, uint256 eta);
    
    error Unauthorized();
    error DelayNotSatisfied();
    error IdenticalTransactionAlreadyQueued();
    error TransactionNotQueued();
    error TimelockNotMet();
    error StaleTransaction();
    error TransactionReverted();
    
     function GRACE_PERIOD() external view returns (uint256);
     function DELAY() external view returns (uint256);
    // function MAXIMUM_DELAY() external view returns (uint256);
    // function MINIMUM_DELAY() external view returns (uint256);
    // function acceptAdmin() external;
    // function admin() external view returns (address);
     function cancelTransaction(address target, uint256 value, string memory
                                signature, bytes memory data, uint256 eta)
                                external;
    function executeTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 eta)
        external
        returns (bytes memory);
    function queueTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 eta)
        external
        returns (bytes32);
    function queuedTransactions(bytes32) external view returns (bool);
}
