// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./events/ExecutorEvents.sol";
import "./utils/Admin.sol";

contract Executor is ExecutorEvents, Admin {
    uint256 public constant GRACE_PERIOD = 14 days; // @todo - do we want this editable?
    uint256 public constant MINIMUM_DELAY = 2 days;
    uint256 public constant MAXIMUM_DELAY = 30 days;

    bool public initialized;
    
    uint256 public delay;
    
    mapping(bytes32 => bool) public queuedTransactions;

    function initialize(address _founders, address _council, uint256 _delay) public {
        require(!initialized, "FrankenDAOExecutor::initialize:already initialized");
        require(_delay >= MINIMUM_DELAY, 'FrankenDAOExecutor::initialize: Delay must exceed minimum delay.');
        require(_delay <= MAXIMUM_DELAY, 'FrankenDAOExecutor::initialize: Delay must not exceed maximum delay.');

        founders = _founders;
        council = _council;
        delay = _delay;
        initialized = true;
    }

    function setDelay(uint256 delay_) public {
        require(isAdmin(), 'FrankenDAOExecutor::setDelay: Call must come from admin.');
        require(delay_ >= MINIMUM_DELAY, 'FrankenDAOExecutor::setDelay: Delay must exceed minimum delay.');
        require(delay_ <= MAXIMUM_DELAY, 'FrankenDAOExecutor::setDelay: Delay must not exceed maximum delay.');
        delay = delay_;

        emit NewDelay(delay);
    }

    function queueTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public returns (bytes32) {
        require(isAdmin(), 'FrankenDAOExecutor::queueTransaction: Call must come from admin.');
        require(
            eta >= getBlockTimestamp() + delay,
            'FrankenDAOExecutor::queueTransaction: Estimated execution block must satisfy delay.'
        );

        // @todo only issue with no description is two identical being queued back to back. maybe block that if already true so they can execute first, then queue next one?
        // i think this is fine but new nouns includes description hash for extra security (in case of malicious conflict). lemme think through it.
        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    function cancelTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public {
        require(isAdmin(), 'FrankenDAOExecutor::cancelTransaction: Call must come from admin.');

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public returns (bytes memory) {
        // @todo SHouldn't anyone willing to pay the gas be able to execute?
        // @todo Does this need to update community voting power in Staking?
        require(isAdmin(), 'FrankenDAOExecutor::executeTransaction: Call must come from admin.');

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(queuedTransactions[txHash], "FrankenDAOExecutor::executeTransaction: Transaction hasn't been queued.");
        require(
            getBlockTimestamp() >= eta,
            "FrankenDAOExecutor::executeTransaction: Transaction hasn't surpassed time lock."
        );
        require(
            getBlockTimestamp() <= eta + GRACE_PERIOD,
            'FrankenDAOExecutor::executeTransaction: Transaction is stale.'
        );

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{ value: value }(callData);
        require(success, 'FrankenDAOExecutor::executeTransaction: Transaction execution reverted.');

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }

    function getBlockTimestamp() internal view returns (uint256) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }

    receive() external payable {}

    fallback() external payable {}
}
