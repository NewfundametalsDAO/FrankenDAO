// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { DeployScript } from "../script/Deploy.s.sol";
import { Test } from "forge-std/Test.sol";

contract TestBase is Test, DeployScript {
    function setUp() virtual public {
        vm.createSelectFork("https://mainnet.infura.io/v3/324422b5714843da8a919967a9c652ac");
        deployAllContractsForTesting();
    }
}