// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Test } from "forge-std/Test.sol";
import { DeployScript } from "../../script/Deploy.s.sol";
import { FrankenDAOErrors } from "../../src/errors/FrankenDAOErrors.sol";
import { IERC721 } from "../../src/interfaces/IERC721.sol";

contract TestBase is Test, FrankenDAOErrors, DeployScript {
    IERC721 frankenpunks;
    IERC721 frankenmonsters;

    function setUp() virtual public {
        vm.createSelectFork(vm.rpcUrl("mainnet"));
        deployAllContractsForTesting();

        frankenpunks = IERC721(FRANKENPUNKS);
        frankenmonsters = IERC721(FRANKENMONSTERS);

        vm.deal(address(staking), 5 ether);
        vm.deal(address(gov), 5 ether);
    }
}
