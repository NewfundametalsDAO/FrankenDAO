pragma solidity ^0.8.13;

import { TestBase } from "../TestBase.t.sol";
import { IERC721 } from "../../src/interfaces/IERC721.sol";

contract TransferRevertTest is TestBase {
    address PUNK_HOLDER = 0xDe8a10880286D6c05F87906308AC0dFA98655E8A;
    uint PUNK_ID = 7488;
    uint[] PUNK_IDS = [PUNK_ID];

    function setUp() public override {
        super.setUp();
        
        vm.startPrank(PUNK_HOLDER);
        IERC721(FRANKENPUNKS).approve(address(staking), PUNK_ID);
        staking.stake(PUNK_IDS, 0);
        vm.stopPrank();
        
        assert(staking.ownerOf(PUNK_ID) == PUNK_HOLDER);
    }

    function testTransferFromReverts() public {       
        vm.prank(PUNK_HOLDER);
        vm.expectRevert("staked tokens cannot be transferred");
        staking.transferFrom(PUNK_HOLDER, address(1), PUNK_ID);
    }

    function testSafeTransferFromReverts() public {
        vm.prank(PUNK_HOLDER);
        vm.expectRevert("staked tokens cannot be transferred");
        staking.safeTransferFrom(PUNK_HOLDER, address(1), PUNK_ID);
    }

    function testSafeTransferFromWithBytesReverts() public {
        vm.prank(PUNK_HOLDER);
        vm.expectRevert("staked tokens cannot be transferred");
        staking.safeTransferFrom(PUNK_HOLDER, address(1), PUNK_ID, bytes(""));
    }
}