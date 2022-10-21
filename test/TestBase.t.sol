// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { DeployScript } from "../script/Deploy.s.sol";
import { Test } from "forge-std/Test.sol";

contract TestBase is Test, DeployScript {
    // Errors
    error NonExistentToken();
    error InvalidDelegation();
    error Paused();
    error InvalidParameter();
    error TokenLocked();
    error ZeroAddress();
    error AlreadyInitialized();
    error ParameterOutOfBounds(string _parameter);
    error InvalidId();
    error InvalidProposal();
    error InvalidStatus();
    error InvalidInput();
    error AlreadyQueued();
    error AlreadyVoted();
    error RequirementsNotMet();
    error NotEligible();

    function setUp() virtual public {
        vm.createSelectFork("https://mainnet.infura.io/v3/324422b5714843da8a919967a9c652ac");
        deployAllContractsForTesting();
    }
}
