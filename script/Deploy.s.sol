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

    address REAL_DEPLOYER = 0x1f3958B482d1Ff1660CEE66F8341Bdc1329De4e0;
    address CREATE2_DEPLOYER = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    address FOUNDER_MULTISIG = 0x1f3958B482d1Ff1660CEE66F8341Bdc1329De4e0; // @todo my goerli, update for mainnet
    address COUNCIL_MULTISIG = 0x20643627A2d02F520A006dF56Acc51E3e67E3Ee5; // @todo dobs goerli, update for mainnet
    
    address FRANKENPUNKS;
    address FRANKENPUNKS_GOERLI = 0x75Ad4CeCB95b330890A93993a2A5A91d8e5D2f03; 
    address FRANKENPUNKS_MAINNET = 0x1FEC856e25F757FeD06eB90548B0224E91095738;

    address FRANKENMONSTERS;
    address FRANKENMONSTERS_GOERLI = 0xaFC74C56264824d92303072C5DB23c04ACa78D81;
    address FRANKENMONSTERS_MAINNET = 0x2cfBCB9e9C3D1ab06eF332f535266444aa8d9570;
    
    bytes32 SALT = bytes32("salty");
    string BASE_TOKEN_URI = "http://frankenpunks.com/uris/"; // @todo fix this

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        
        _deployAllContracts(true, false);
        
        console.log("executor deployed to: ", address(executor));
        console.log("govImpl deployed to: ", address(govImpl));
        console.log("govProxy deployed to: ", address(gov));
        console.log("staking deployed to: ", address(staking));

        payable(address(gov)).transfer(0.5 ether);
        payable(address(staking)).transfer(0.5 ether);
        console.log("eth sent to gov & staking");

        vm.stopBroadcast();
    }

    function _deployAllContracts(bool realDeploy, bool mainnet) internal {

        address create2Deployer = realDeploy ? CREATE2_DEPLOYER : address(this);
        address deployer = realDeploy ? REAL_DEPLOYER : address(this);

        FRANKENPUNKS = mainnet ? FRANKENPUNKS_MAINNET : FRANKENPUNKS_GOERLI;
        FRANKENMONSTERS = mainnet ? FRANKENMONSTERS_MAINNET : FRANKENMONSTERS_GOERLI;

        bytes memory proxyCreationCode = abi.encodePacked(
            type(GovernanceProxy).creationCode,
            abi.encode(FRANKENPUNKS, deployer, bytes(""))
        );

        address expectedGovProxyAddr = address(uint160(uint256(keccak256(
            abi.encodePacked(bytes1(0xff), create2Deployer, SALT, keccak256(proxyCreationCode))
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
            BASE_TOKEN_URI
        );

        // create governance (no need to initialize because nothing vulnerable in implementation)
        govImpl = new Governance();

        // create governance proxy and initialize
        gov = Governance(payable(address(new GovernanceProxy{salt:SALT}(FRANKENPUNKS, deployer, bytes("")))));
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

        (bool changeAdminSuccess, ) = address(gov).call(
            abi.encodeWithSignature(
                "changeAdmin(address)",
                (address(executor))
            )
        );
        require(changeAdminSuccess, "proxy admin change failed");
    }

    // Harness so we can use the same script for testing.
    function deployAllContractsForTesting() public {
        return _deployAllContracts(false, true);
    }
}
