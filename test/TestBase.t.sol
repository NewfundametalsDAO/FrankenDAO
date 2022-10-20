// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { DeployScript } from "../script/Deploy.s.sol";
import { Test } from "forge-std/Test.sol";

import { IExecutor } from "src/interfaces/IExecutor.sol";
import { IStaking } from "src/interfaces/IStaking.sol";
import { IGovernance } from "src/interfaces/IGovernance.sol";

import "forge-std/Test.sol";
import "../src/Staking.sol";
import "oz/utils/Strings.sol";


contract TestBase is Test, DeployScript {
    function setUp() public {
        vm.createSelectFork("https://mainnet.infura.io/v3/324422b5714843da8a919967a9c652ac");
        deployAllContracts();
    }
}