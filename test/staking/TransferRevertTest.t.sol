// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { StakingBase } from "../bases/StakingBase.t.sol";
import { IERC721 } from "../../src/interfaces/IERC721.sol";

contract TransferRevertTests is StakingBase {
    uint ID = 0;

    function testTransferFromReverts() public {       
        address owner = mockStakeSingle(ID);
        vm.prank(owner);
        vm.expectRevert(StakedTokensCannotBeTransferred.selector);
        staking.transferFrom(owner, address(1), ID);
    }

    function testSafeTransferFromReverts() public {
        address owner = mockStakeSingle(ID);
        vm.prank(owner);
        vm.expectRevert(StakedTokensCannotBeTransferred.selector);
        staking.safeTransferFrom(owner, address(1), ID);
    }

    function testSafeTransferFromWithBytesReverts() public {
        address owner = mockStakeSingle(ID);
        vm.prank(owner);
        vm.expectRevert(StakedTokensCannotBeTransferred.selector);
        staking.safeTransferFrom(owner, address(1), ID, bytes(""));
    }
}