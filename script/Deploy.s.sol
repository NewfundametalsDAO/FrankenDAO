// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "src/proxy/Proxy.sol";
import "src/Executor.sol";
import "src/Staking.sol";
import "src/Governance.sol";

contract DeployScript is Script {
    Executor executorImpl;
    Executor executorProxy;
    Staking staking;
    Governance govImpl;
    Governance govProxy;

    address FOUNDER_MULTISIG; // FILL THIS IN
    address COUNCIL_MULTISIG; // FILL THIS IN
    address FRANKENPUNKS; // FILL THIS IN
    address FRANKENMONSTERS; // FILL THIS IN
    uint SALT = 1234;

    function run() public {
        vm.startBroadcast();
        
        // create executor and initialize to avoid hacks
        executorImpl = new Executor();
        executorImpl.initialize(address(0), address(0), 2 days);

        // create executor proxy and initialize
        executorProxy = new Proxy(
            executorImpl,
            abi.encodeWithSignature(
                "initialize(address,address,uint)", 
                FOUNDER_MULTISIG,
                COUNCIL_MULTISIG,
                2 days
            )
        );        

        // create governance and initialize to avoid hacks
        govImpl = new Governance();
        govImpl.initialize(address(0), address(0), address(0), [address(0), address(0)], 10000, 10000, 100, 100);

        // precompute staking address
        bytes memory bytecode = abi.encodePacked(
            type(Staking).creationCode,
            abi.encode(
                FRANKENPUNKS,
                FRANKENMONSTERS,
                address(govProxy),
                address(executorProxy),
                4 weeks,
                20,
                100,
                200,
                200
            )
        );
        address stakingAddr = address(uint160(keccak256(
            abi.encodePacked(bytes1(0xff), address(this), SALT, keccak256(bytecode))
        )));

        // create governance proxy and initialize
        govProxy = new Proxy(
            govImpl,
            abi.encodeWithSignature(
                "initialize(address,address,address,address[],uint256,uint256,uint256,uint256)",
                address(executorProxy),
                stakingAddr,
                FOUNDER_MULTISIG,
                COUNCIL_MULTISIG,
                [address(0), address(0)], // vetoers, i think we're removing
                7 days,
                1 days,
                100, // changing this to fixed amount, right?
                100 // changing this to fixed amount, right?
            )
        );

        // create staking 
        staking = new Staking{salt: SALT}(
            FRANKENPUNKS,
            FRANKENMONSTERS,
            address(govProxy),
            address(executorProxy),
            4 weeks,
            20,
            100,
            200,
            200
        );

        console.log("executorImpl", address(executorImpl));
        console.log("executorProxy", address(executorProxy));
        console.log("govImpl", address(govImpl));
        console.log("govProxy", address(govProxy));
        console.log("predicted staking", stakingAddr);
        console.log("staking", address(staking));

        vm.stopBroadcast();
    }
}
