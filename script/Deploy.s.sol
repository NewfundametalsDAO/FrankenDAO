 // SPDX-License-Identifier: UNLICENSED
 pragma solidity ^0.8.13;

import { Script } from "forge-std/Script.sol";
import { FrankenDAOProxy } from "src/proxy/Proxy.sol";
import { Executor } from "src/Executor.sol";
import { Staking } from "src/Staking.sol";
import { Governance } from "src/Governance.sol";

import { IExecutor } from "src/interfaces/IExecutor.sol";
import { IStaking } from "src/interfaces/IStaking.sol";
import { IGovernance } from "src/interfaces/IGovernance.sol";

contract DeployScript is Script {
    IExecutor executor;
    IStaking staking;
    IGovernance govImpl;
    IGovernance govProxy;

    address FOUNDER_MULTISIG;
    address COUNCIL_MULTISIG;
    address FRANKENPUNKS = 0x1FEC856e25F757FeD06eB90548B0224E91095738;
    address FRANKENMONSTERS;
    bytes32 SALT = bytes32("salty");

    function run() public {
        vm.startBroadcast();

        address expectedGovProxyAddr = address(uint160(keccak256(
            abi.encodePacked(bytes1(0xff), address(this), SALT, keccak256(type(Governance).creationCode;))
        )));
        
        // create executor
        executor = new Executor(expectedGovProxyAddr);

        // create staking 
        staking = new Staking(
            FRANKENPUNKS,
            FRANKENMONSTERS,
            expectedGovProxyAddr,
            address(executor),
            4 weeks, // maxStakeBonusTime
            20, // maxStakeBonusAmount
            100, // votesMultiplier
            200, // proposalsCreatedMultiplier
            200 // proposalsPassedMultiplier
        );

        // create governance and initialize impl to avoid hacks
        govImpl = new Governance();
        govImpl.initialize(address(0), address(0), address(0), address(0), 7 days, 1 days, 0, 100);

        // create governance proxy and initialize
        govProxy = IGovernance(
            new FrankenDAOProxy(
                govImpl,
                address(executor),
                abi.encodeWithSignature(
                    "initialize(address,address,address,address,uint256,uint256,uint256,uint256)",
                    address(staking),
                    address(executor),
                    FOUNDER_MULTISIG,
                    COUNCIL_MULTISIG,
                    7 days, // Voting Period
                    1 days, // Voting Delay
                    500, // Proposal BPS: 5%
                    2000 // Quorum BPS: 20%
                )
            )
        );

        assert(address(govProxy) == expectedGovProxyAddr, "governance proxy address mismatch");

        console.log("executor deployed to: ", address(executor));
        console.log("govImpl deployed to: ", address(govImpl));
        console.log("govProxy deployed to: ", address(govProxy));
        console.log("staking deployed to: ", address(staking));

        vm.stopBroadcast();
    }
}
