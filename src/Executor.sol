// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./interfaces/IExecutor.sol";

contract Executor is IExecutor {
    uint256 public constant DELAY = 2 days;
    uint256 public constant GRACE_PERIOD = 14 days;
    
    address governance;
    mapping(bytes32 => bool) public queuedTransactions;

    /////////////////////////////////
    ////////// CONSTRUCTOR //////////
    /////////////////////////////////

    constructor(address _governance) {
        if (_governance == address(0)) revert ZeroAddress();
        governance = _governance;
    }

    /////////////////////////////////
    /////////// MODIFIERS ///////////
    /////////////////////////////////

    modifier onlyGovernance() {
        if (msg.sender != governance) revert Unauthorized();
        _;
    }

    /////////////////////////////////
    ////////// TX EXECUTION /////////
    /////////////////////////////////

    function queueTransaction(
        address _target,
        uint256 _value,
        string memory _signature,
        bytes memory _data,
        uint256 _eta
    ) public onlyGovernance returns (bytes32) {
        if (block.timestamp + DELAY > _eta) revert DelayNotSatisfied();

        bytes32 txHash = keccak256(abi.encode(_target, _value, _signature, _data, _eta));
        if(queuedTransactions[txHash]) revert IdenticalTransactionAlreadyQueued();
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, _target, _value, _signature, _data, _eta);
        return txHash;
    }

    function cancelTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public onlyGovernance {
        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    function executeTransaction(
        address _target,
        uint256 _value,
        string memory _signature,
        bytes memory _data,
        uint256 _eta
    ) public onlyGovernance returns (bytes memory) {
        bytes32 txHash = keccak256(abi.encode(_target, _value, _signature, _data, _eta));
        if (!queuedTransactions[txHash]) revert TransactionNotQueued();
        if (_eta > block.timestamp) revert TimelockNotMet();
        if (block.timestamp > _eta + GRACE_PERIOD) revert StaleTransaction(); // @todo this is actually useless because it's caught in governance

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(_signature).length == 0) {
            callData = _data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(_signature))), _data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = _target.call{ value: _value }(callData);
        if (!success) revert TransactionReverted();

        emit ExecuteTransaction(txHash, _target, _value, _signature, _data, _eta);

        return returnData;
    }

    receive() external payable {}

    fallback() external payable {}
}
