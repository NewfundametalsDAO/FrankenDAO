pragma solidity ^0.8.13;

pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { GovernanceBase } from "../bases/GovernanceBase.t.sol";
import { IGovernance } from "../../src/interfaces/IGovernance.sol";

contract ExecutorTests is GovernanceBase {
    // Test that successful proposals revert if executed before delay.
    function testExecutor__RevertsBeforeDelay() public {
        uint proposalId = _createSuccessfulProposal();
        gov.queue(proposalId);

        vm.expectRevert(TimelockNotMet.selector);
        gov.execute(proposalId);
    }

    // Test that successful proposals revert if not executed in grace period.
    function testExecutor__RevertsAfterGracePeriod() public {
        uint proposalId = _createSuccessfulProposal();
        gov.queue(proposalId);
        vm.warp(block.timestamp + executor.DELAY() + executor.GRACE_PERIOD() + 1);

        vm.expectRevert(InvalidStatus.selector);
        gov.execute(proposalId);
    }
}
