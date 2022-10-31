 // SPDX-License-Identifier: UNLICENSED
 pragma solidity ^0.8.13;

import { Script } from "forge-std/Script.sol";
import "forge-std/Test.sol";

import { GovernanceProxy } from "src/proxy/GovernanceProxy.sol";
import { Executor } from "src/Executor.sol";
import { Staking } from "src/Staking.sol";
import { Governance } from "src/Governance.sol";

contract DeployScript is Script {
    Executor executor;
    Staking staking;
    Governance govImpl;
    Governance gov;

    address FOUNDER_MULTISIG = address(2);
    address COUNCIL_MULTISIG = address(3);
    address FRANKENPUNKS = 0x1FEC856e25F757FeD06eB90548B0224E91095738;
    address FRANKENMONSTERS = address(1);
    bytes32 SALT = bytes32("salty");

    function run() public {
        vm.startBroadcast();
        _deployAllContracts();
        vm.stopBroadcast();

        console.log("executor deployed to: ", address(executor));
        console.log("govImpl deployed to: ", address(govImpl));
        console.log("govProxy deployed to: ", address(gov));
        console.log("staking deployed to: ", address(staking));
    }

    function _deployAllContracts() internal {
        bytes memory proxyCreationCode = abi.encodePacked(
            type(GovernanceProxy).creationCode,
            abi.encode(FRANKENPUNKS, address(this), bytes(""))
        );

        address expectedGovProxyAddr = address(uint160(uint256(keccak256(
            abi.encodePacked(bytes1(0xff), address(this), SALT, keccak256(proxyCreationCode))
        ))));
        
        // create executor
        executor = new Executor(expectedGovProxyAddr);

        // create staking 
        staking = new Staking(
            FRANKENPUNKS,
            FRANKENMONSTERS,
            expectedGovProxyAddr,
            address(executor),
            FOUNDER_MULTISIG,
            COUNCIL_MULTISIG,
            4 weeks, // maxStakeBonusTime
            20, // maxStakeBonusAmount
            100, // votesMultiplier
            200, // proposalsCreatedMultiplier
            200, // proposalsPassedMultiplier,
            50 // monsterMultiplier
        );

        // create governance 
        // @todo no need to initialize because it's fine if someone else initializes?
        govImpl = new Governance();

        // create governance proxy and initialize
        gov = Governance(address(new GovernanceProxy{salt:SALT}(FRANKENPUNKS, address(this), bytes(""))));

        require(address(gov) == expectedGovProxyAddr, "governance proxy address mismatch");

        (bool upgradeSuccess, bytes memory uR) = address(gov).call
            (abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)",
                address(govImpl),
                abi.encodeWithSignature(
                    "initialize(address,address,address,address,uint256,uint256,uint256,uint256)",
                    address(staking),
                    address(executor),
                    FOUNDER_MULTISIG,
                    COUNCIL_MULTISIG,
                    7 days, // Voting Period
                    1 days, // Voting Delay
                    500, // Proposal BPS: 5%
                    2000 // Quorum BPS: 35%
                )
            )
        );
        require(upgradeSuccess, "proxy upgrade failed");

        (bool changeAdminSuccess, bytes memory caR) = address(gov).call(
            abi.encodeWithSignature(
                "changeAdmin(address)",
                (address(executor))
            )
        );
        require(changeAdminSuccess, "proxy admin change failed");
    }

    // Harness so we can use the same script for testing.
    function deployAllContractsForTesting() public {
        return _deployAllContracts();
    }
}
