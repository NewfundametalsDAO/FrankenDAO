pragma solidity ^0.8.13;

import { StakingBase } from "./StakingBase.t.sol";
import { IERC721 } from "../../src/interfaces/IERC721.sol";

contract TransferRevertTest is StakingBase {

    function testTransferFromReverts() public {       
        uint[] memory ids = new uint[](2);
        ids[0] = 0;
        ids[1] = 1;
        address[] memory owners = mockStake(ids);
        vm.prank(owners[0]);
        vm.expectRevert("staked tokens cannot be transferred");
        staking.transferFrom(owners[0], address(1), ids[0]);
    }

    // function testSafeTransferFromReverts() public {
    //     vm.prank(PUNK_HOLDER);
    //     vm.expectRevert("staked tokens cannot be transferred");
    //     staking.safeTransferFrom(PUNK_HOLDER, address(1), PUNK_ID);
    // }

    // function testSafeTransferFromWithBytesReverts() public {
    //     vm.prank(PUNK_HOLDER);
    //     vm.expectRevert("staked tokens cannot be transferred");
    //     staking.safeTransferFrom(PUNK_HOLDER, address(1), PUNK_ID, bytes(""));
    // }
}