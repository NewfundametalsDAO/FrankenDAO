// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { StakingBase } from "../bases/StakingBase.t.sol";
import { IERC721 } from "../../src/interfaces/IERC721.sol";

contract TransferRevertTests is StakingBase {

    // Test that transferFrom reverts
    function testTransferReverts__TransferFromReverts() public {       
        address owner = mockStakeSingle(PUNK_ID);
        vm.prank(owner);
        vm.expectRevert(StakedTokensCannotBeTransferred.selector);
        staking.transferFrom(owner, address(1), PUNK_ID);
    }

    // Test that safeTransferFrom reverts
    function testTransferReverts__SafeTransferFromReverts() public {
        address owner = mockStakeSingle(PUNK_ID);
        vm.prank(owner);
        vm.expectRevert(StakedTokensCannotBeTransferred.selector);
        staking.safeTransferFrom(owner, address(1), PUNK_ID);
    }

    // Test that safeTransferFrom with data bytes reverts
    function testTransferReverts__SafeTransferFromWithBytesReverts() public {
        address owner = mockStakeSingle(PUNK_ID);
        vm.prank(owner);
        vm.expectRevert(StakedTokensCannotBeTransferred.selector);
        staking.safeTransferFrom(owner, address(1), PUNK_ID, bytes(""));
    }
}