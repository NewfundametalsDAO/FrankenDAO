// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { GovernanceBase } from "../bases/GovernanceBase.t.sol";
import { Governance } from "../../src/Governance.sol";
import { IGovernance } from "../../src/interfaces/IGovernance.sol";
import { GovernanceProxy } from "../../src/proxy/GovernanceProxy.sol";

contract GovProxyTests is GovernanceBase {

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

    // Test that AdminOnly functions on the proxy can only be called by the admin.
    function testGovProxy__AdminOnly() public {
        GovernanceProxy proxy = GovernanceProxy(payable(address(gov)));

        vm.expectRevert(NotAuthorized.selector);
        proxy.changeAdmin(address(this));

        vm.expectRevert(NotAuthorized.selector);
        proxy.upgradeTo(address(FRANKENPUNKS));

        vm.expectRevert(NotAuthorized.selector);
        proxy.upgradeToAndCall(address(FRANKENPUNKS), abi.encodeWithSignature("admin()"));
    }

    // Test that governance can't be reinitialized.
    function testGovProxy__CantReinitialize() public {
        vm.expectRevert(AlreadyInitialized.selector);
        gov.initialize(
            address(staking), 
            address(executor), 
            FOUNDER_MULTISIG,
            COUNCIL_MULTISIG,
            2 days, 2 days, 500, 500
        );
    }
}
