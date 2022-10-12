// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "src/proxy/Proxy.sol";
import "src/Executor.sol";
import "src/Staking.sol";
import "src/Governance.sol";

contract CounterScript is Script {
    Executor executorImpl;
    Executor executorProxy;
    Staking staking;
    Governance govImpl;
    Governance govProxy;

    address FOUNDER_MULTISIG; // FILL THIS IN
    address COUNCIL_MULTISIG; // FILL THIS IN
    address FRANKENPUNKS;
    address FRANKENMONSTERS;

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

        // create governance proxy and initialize
        govProxy = new Proxy(
            govImpl,
            abi.encodeWithSignature(
                "initialize(address,address,address,address[],uint256,uint256,uint256,uint256)",
                address(executorProxy),
                address(0),
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
        staking = new Staking(
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

        govProxy.setStakingAddress(address(staking)); // @todo make this function or figure out how to predetermine address for above

        vm.stopBroadcast();
    }
}
