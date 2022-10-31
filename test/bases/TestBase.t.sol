// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Test } from "forge-std/Test.sol";

import { DeployScript } from "../../script/Deploy.s.sol";

import { IGovernance } from "../../src/interfaces/IGovernance.sol";
import { IStaking } from "../../src/interfaces/IStaking.sol";

contract TestBase is Test, DeployScript {
    // Errors
    error NonExistentToken();
    error InvalidDelegation();
    error Paused();
    error InvalidParameter();
    error TokenLocked();
    error AlreadyInitialized();
    error ParameterOutOfBounds();
    error InvalidId();
    error InvalidProposal();
    error InvalidStatus();
    error InvalidInput();
    error AlreadyQueued();
    error AlreadyVoted();
    error RequirementsNotMet();
    error NotEligible();
    error Unauthorized();
    error NotRefundable();
    error InsufficientRefundBalance();
    error DelayNotSatisfied();
    error IdenticalTransactionAlreadyQueued();
    error TransactionNotQueued();
    error TimelockNotMet();
    error StaleTransaction();
    error TransactionReverted();
    error StakedTokensCannotBeTransferred();

    function setUp() virtual public {
        vm.createSelectFork(vm.rpcUrl("mainnet"));
        deployAllContractsForTesting();
    }

    function dealRefundBalance() internal {
        vm.deal(address( staking ), 10 ether);
        vm.deal(address( gov ), 10 ether);
    }

    // function setGovernanceRefundStatus(IGovernance.RefundStatus _status) internal {
    //     vm.prank(address(executor));
    //     gov.setRefund(_status);
    // }

    // function setStakingRefundStatus(IStaking.RefundStatus _status) internal {
    //     vm.prank(address(executor));
    //     staking.setRefund(_status);
    // }
}
