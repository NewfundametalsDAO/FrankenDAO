pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { GovernanceBase } from "./GovernanceBase.t.sol";
import { Governance } from "../../src/Governance.sol";
import { IGovernance } from "../../src/interfaces/IGovernance.sol";
import { GovernanceProxy } from "../../src/proxy/GovernanceProxy.sol";

contract ProxyTests is GovernanceBase {
    // Test that we can upgrade the governance implementation contract.
    function testGovProxy__UpgradeImplementation() public {
        address fakeImpl = address(new Governance());
        uint proposalId = _passCustomProposal("upgradeTo(address)", abi.encode(fakeImpl));

        gov.queue(proposalId);
        vm.warp(block.timestamp + executor.DELAY());
        gov.execute(proposalId);

        GovernanceProxy proxy = GovernanceProxy(payable(address(gov)));
        assert(proxy.implementation() == address(fakeImpl));    
    }

    // Test that we can upgrade the admin on the governance proxy contract.
    function testGovProxy__UpgradeAdmin() public {
        address newAdmin = makeAddr("newAdmin");
        uint proposalId = _passCustomProposal("changeAdmin(address)", abi.encode(newAdmin));

        gov.queue(proposalId);
        vm.warp(block.timestamp + executor.DELAY());
        gov.execute(proposalId);

        GovernanceProxy proxy = GovernanceProxy(payable(address(gov)));
        assert(proxy.admin() == newAdmin);    
    }
}
