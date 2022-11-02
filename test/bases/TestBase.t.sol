// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Test } from "forge-std/Test.sol";

import { DeployScript } from "../../script/Deploy.s.sol";
import { FrankenDAOErrors } from "../../src/errors/FrankenDAOErrors.sol";

import { IGovernance } from "../../src/interfaces/IGovernance.sol";
import { IStaking } from "../../src/interfaces/IStaking.sol";

contract TestBase is Test, FrankenDAOErrors, DeployScript {
    function setUp() virtual public {
        vm.createSelectFork(vm.rpcUrl("mainnet"));
        deployAllContractsForTesting();
    }
}
