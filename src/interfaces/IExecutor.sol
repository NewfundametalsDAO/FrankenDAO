pragma solidity ^0.8.10;

interface IExecutor {
    event NewDelay(uint256 indexed newDelay);
    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint256 value, string signature, bytes data, uint256 eta);
    event ExecuteTransaction( bytes32 indexed txHash, address indexed target, uint256 value, string signature, bytes data, uint256 eta);
    event QueueTransaction( bytes32 indexed txHash, address indexed target, uint256 value, string signature, bytes data, uint256 eta);
    
    
    // function GRACE_PERIOD() external view returns (uint256);
    // function MAXIMUM_DELAY() external view returns (uint256);
    // function MINIMUM_DELAY() external view returns (uint256);
    // function acceptAdmin() external;
    // function admin() external view returns (address);
    // function cancelTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 eta)
    //     external;
    function delay() external view returns (uint256);
    function executeTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 eta)
        external
        returns (bytes memory);
    function initialize(address admin_, uint256 delay_) external;
    // function initialized() external view returns (bool);
    // function pendingAdmin() external view returns (address);
    function queueTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 eta)
        external
        returns (bytes32);
    // function queuedTransactions(bytes32) external view returns (bool);
    function setDelay(uint256 delay_) external;
    // function setPendingAdmin(address pendingAdmin_) external;
}
