// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { GovernanceBase } from "../bases/GovernanceBase.t.sol";
import { IGovernance } from "../../src/interfaces/IGovernance.sol";

contract ActiveProposalTests is GovernanceBase {

    // Test that we can ban a user and it stops them from proposing.
    function testGovBan__BanUser() public {
        vm.prank(FOUNDER_MULTISIG);
        gov.banProposer(proposer, true);

        vm.expectRevert(NotAuthorized.selector);
        uint proposalId = _createProposal();
    }
}
