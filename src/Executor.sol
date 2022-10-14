// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./interfaces/IExecutor.sol";
import "./utils/Admin.sol";

contract Executor is IExecutor, Admin {
    uint256 public constant GRACE_PERIOD = 14 days;
    uint256 public constant MINIMUM_DELAY = 2 days;
    uint256 public constant MAXIMUM_DELAY = 30 days;

    address governance;
    uint256 public delay;
    bool public initialized;
    
    mapping(bytes32 => bool) public queuedTransactions;

    modifier onlyGovernance() {
        require(msg.sender == governance, "FrankenDAO::onlyGovernance: admin only");
        _;
    }

    function initialize(address _governance, uint256 _delay) public {
        require(!initialized, "FrankenDAOExecutor::initialize:already initialized");
        require(_delay >= MINIMUM_DELAY, 'FrankenDAOExecutor::initialize: Delay must exceed minimum delay.');
        require(_delay <= MAXIMUM_DELAY, 'FrankenDAOExecutor::initialize: Delay must not exceed maximum delay.');
        require(_governance != address(0), 'FrankenDAOExecutor::initialize: Governance address cannot be zero address.');

        governance = _governance;
        delay = _delay;
        initialized = true;
    }

    function queueTransaction(
        address _target,
        uint256 _value,
        string memory _signature,
        bytes memory _data,
        uint256 _eta
    ) public onlyGovernance returns (bytes32) {
        require(
            _eta >= block.timestamp + delay,
            'FrankenDAOExecutor::queueTransaction: Estimated execution block must satisfy delay.'
        );

        bytes32 txHash = keccak256(abi.encode(_target, _value, _signature,
                                              _data, _eta));
        require(queuedTransactions[txHash] == false, "FrankenDAOExecutor::queueTransaction: identical tx already queued");
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, _target, _value, _signature, _data, _eta);
        return txHash;
    }

    function cancelTransaction(
        address _target,
        uint256 _value,
        string memory _signature,
        bytes memory _data,
        uint256 _eta
    ) public onlyGovernance {

        bytes32 txHash = keccak256(abi.encode(_target, _value, _signature,
                                              _data, _eta));
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, _target, _value, _signature, _data, _eta);
    }

    function executeTransaction(
        address _target,
        uint256 _value,
        string memory _signature,
        bytes memory _data,
        uint256 _eta
    ) public onlyGovernance returns (bytes memory) {
        bytes32 txHash = keccak256(abi.encode(_target, _value, _signature,
                                              _data, _eta));
        require(queuedTransactions[txHash], "FrankenDAOExecutor::executeTransaction: Transaction hasn't been queued.");
        require(
            block.timestamp >= _eta,
            "FrankenDAOExecutor::executeTransaction: Transaction hasn't surpassed time lock."
        );
        require(
            block.timestamp <= _eta + GRACE_PERIOD,
            'FrankenDAOExecutor::executeTransaction: Transaction is stale.'
        );

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(_signature).length == 0) {
            callData = _data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(_signature))), _data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = _target.call{ value: _value }(callData);
        require(success, 'FrankenDAOExecutor::executeTransaction: Transaction execution reverted.');

        emit ExecuteTransaction(txHash, _target, _value, _signature, _data, _eta);

        return returnData;
    }

    /////////////////////////////////
    //////// OWNER OPERATIONS ///////
    /////////////////////////////////

    function setDelay(uint256 _delay) public {
        require(msg.sender == address(this), "FrankenDAOExecutor::setDelay: self only");
        require(_delay >= MINIMUM_DELAY, 'FrankenDAOExecutor::setDelay: delay must exceed minimum delay.');
        require(_delay <= MAXIMUM_DELAY, 'FrankenDAOExecutor::setDelay: delay must not exceed maximum delay.');
        
        emit NewDelay(delay = _delay);
    }

    receive() external payable {}

    fallback() external payable {}
}
