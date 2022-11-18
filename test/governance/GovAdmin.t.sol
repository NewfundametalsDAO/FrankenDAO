// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { GovernanceBase } from "../bases/GovernanceBase.t.sol";
import { IGovernance } from "../../src/interfaces/IGovernance.sol";

contract GovAdminTests is GovernanceBase {
    // Test that the original values for multisigs and executor are set correctly.
    function testGovAdmin__InitialValues() view public {
        assert(gov.founders() == FOUNDER_MULTISIG);
        assert(gov.council() == COUNCIL_MULTISIG);
        assert(gov.executor() == executor);
    }

    // Test that only the founder can transfer founder multisig.
    function testGovAdmin__TwoStepFounderChangeFlow() public {
        address newFounder = makeAddr("newFounder");

        // Non founder can't set pending founders.
        vm.expectRevert(NotAuthorized.selector);
        gov.setPendingFounders(newFounder);

        // Founder can set pending founders.
        vm.prank(FOUNDER_MULTISIG);
        gov.setPendingFounders(newFounder);

        // Pending founder set correctly and doesn't change founder.
        assert(gov.pendingFounders() == newFounder);
        assert(gov.founders() == FOUNDER_MULTISIG);

        // Non pending founder can't call acceptFounders.
        vm.expectRevert(NotAuthorized.selector);
        gov.acceptFounders();

        // Pending founder can call acceptFounders.
        vm.prank(newFounder);
        gov.acceptFounders();

        // Founder changed and pending founder resets to zero.
        assert(gov.founders() == newFounder);
        assert(gov.pendingFounders() == address(0));
    }

    // Test that only the founder can revoke pending founder multisig.
    function testGovAdmin__FounderRevoke() public {
        // Non founder can't revoke pending founder.
        vm.expectRevert(NotAuthorized.selector);
        gov.revokeFounders();

        // Founder can revoke pending founder.
        vm.prank(FOUNDER_MULTISIG);
        gov.revokeFounders();

        // Founder resets to zero.
        assert(gov.founders() == address(0));
        assert(gov.pendingFounders() == address(0));
    }

    // Test that council can get the council multisig.
    function testGovAdmin__CouncilCanSetCouncil() public {
        address newCouncil = makeAddr("newCouncil");
        
        vm.expectRevert(NotAuthorized.selector);
        vm.prank(address(executor));
        gov.setCouncil(newCouncil);

        vm.prank(COUNCIL_MULTISIG);
        gov.setCouncil(newCouncil);
        assert(gov.council() == newCouncil);
    }

    // Test that council can set the pauser role.
    function testGovAdmin__CouncilCanSetPauser() public {
        address newPauser = makeAddr("newPauser");

        vm.prank(COUNCIL_MULTISIG);
        gov.setPauser(newPauser);
        assert(gov.pauser() == newPauser);
    }

    // Test that governance can set the pauser role but not others.
    function testGovAdmin__GovernanceCanSetPauser() public {
        address newUser = makeAddr("newUser");
        
        vm.expectRevert(NotAuthorized.selector);
        vm.prank(address(executor));
        gov.setPendingFounders(newUser);

        vm.expectRevert(NotAuthorized.selector);
        vm.prank(address(executor));
        gov.setCouncil(newUser);

        vm.expectRevert(NotAuthorized.selector);
        vm.prank(address(executor));
        gov.setVerifier(newUser);

        vm.prank(address(executor));
        gov.setPauser(newUser);

        assert(gov.pauser() == newUser);
    }

    // Test that the verifier role works.
    function testGovAdmin__VerifierRoleCanBeSetAndVerify() public {
        address verifier = makeAddr("verifier");

        vm.prank(COUNCIL_MULTISIG);
        gov.setVerifier(verifier);

        uint proposalId = _createProposal();

        vm.prank(verifier);
        gov.verifyProposal(proposalId);

        vm.warp(block.timestamp + gov.votingDelay());

        assert(_checkState(proposalId, IGovernance.ProposalState.Active));
    }
    
}