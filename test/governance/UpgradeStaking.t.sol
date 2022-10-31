pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { GovernanceBase } from "../bases/GovernanceBase.t.sol";
import { Staking } from "../../src/Staking.sol";

contract UpgradeStakingTests is GovernanceBase {
    // Test that governance can upgrade the Staking contract address.
    function testGovUpgrades__UpgradeStaking() public {
        address fakeStaking = address(new Staking(
            FRANKENPUNKS,
            FRANKENMONSTERS,
            address(gov),
            address(executor),
            FOUNDER_MULTISIG,
            COUNCIL_MULTISIG,
            4 weeks, 20, 100, 200, 200, 
            50
        ));

        uint proposalId = _passCustomProposal("setStakingAddress(address)", abi.encode(fakeStaking));

        gov.queue(proposalId);
        vm.warp(block.timestamp + executor.DELAY());
        gov.execute(proposalId);

        assert(address(gov.staking()) == fakeStaking);    
    }

}