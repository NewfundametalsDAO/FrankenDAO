// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./interfaces/IExecutor.sol";
import { FrankenDAOErrors } from "./utils/FrankenDAOErrors.sol";

contract Executor is IExecutor, FrankenDAOErrors {
    uint256 public constant DELAY = 2 days;
    uint256 public constant GRACE_PERIOD = 14 days;
    
    address governance;
    mapping(bytes32 => bool) public queuedTransactions;

    /////////////////////////////////
    ////////// CONSTRUCTOR //////////
    /////////////////////////////////

    constructor(address _governance) {
        governance = _governance;
    }

    /////////////////////////////////
    /////////// MODIFIERS ///////////
    /////////////////////////////////

    modifier onlyGovernance() {
        if (msg.sender != governance) revert NotAuthorized();
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
    ) public onlyGovernance returns (bytes32 txHash) {
        if (block.timestamp + DELAY > _eta) revert DelayNotSatisfied();

        txHash = keccak256(abi.encode(_target, _value, _signature, _data, _eta));
        if (queuedTransactions[txHash]) revert IdenticalTransactionAlreadyQueued();
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, _target, _value, _signature, _data, _eta);
    }

    function cancelTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public onlyGovernance {
        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        if (!queuedTransactions[txHash]) revert TransactionNotQueued();
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
        
        // We don't need to check if it's expired, because this will be caught by the Governance contract.
        // (If we are past the grace period, proposal state will be Expired and execute() will revert.)
        if (!queuedTransactions[txHash]) revert TransactionNotQueued();
        if (_eta > block.timestamp) revert TimelockNotMet();
        
        queuedTransactions[txHash] = false;
        
        if (bytes(_signature).length > 0) {
            _data = abi.encodeWithSignature(_signature, _data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = _target.call{ value: _value }(_data);
        if (!success) revert TransactionReverted();

        emit ExecuteTransaction(txHash, _target, _value, _signature, _data, _eta);
        return returnData;
    }

    receive() external payable {}

    fallback() external payable {}
}
