// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract ExecutorEvents {
    event NewDelay(uint256 indexed newDelay);
    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint256 value, string signature, bytes data, uint256 eta);
    event ExecuteTransaction( bytes32 indexed txHash, address indexed target, uint256 value, string signature, bytes data, uint256 eta);
    event QueueTransaction( bytes32 indexed txHash, address indexed target, uint256 value, string signature, bytes data, uint256 eta);
}
