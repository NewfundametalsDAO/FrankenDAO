pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/Staking.sol";
import "../utils/mocks/Token.sol";

import { StakingBase } from "./StakingBase.t.sol";

contract LockedTest is StakingBase {
    uint[] ids = [6251, 4122];
    address[] targets = [0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B,0x35A18000230DA775CAc24873d00Ff85BccdeD550,0x70e36f6BF80a52b3B46b3aF8e106CC0ed743E8e4];
    uint256[] values = [0,0,0];
    string[] signatures
    = ["_setMarketBorrowCaps(address[],uint256[])","_setInterestRateModel(address)","_setInterestRateModel(address)"];
    bytes[] data = "0x00000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000100000000000000000000000070e36f6bf80a52b3b46b3af8e106cc0ed743e8e40000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000001fc3842bd1f071c00000,0x000000000000000000000000d956188795ca6f4a74092ddca33e0ea4ca3a1395,0x000000000000000000000000d88b94128ff2b8cf2d7886cd1c1e46757418ca2a";


    // reverts if unstaking during a vote
    function testLocking__RevertsIfUnstakingDuringVoting() public {
        // addr 1 stakes
        address playerOne = mockStakeSingle(ids[0]);
        // addr 2 stakes
        address playerTwo = mockStakeSingle(ids[1]);

        // addr 2 delegates to addr 1
        vm.prank(playerOne);
        frankenpunks.delegate(playerOne);

        // create proposal
        uint256 proposalId = govImpl.propose(
            targets,
            values,
            signatures,
            data
        );

        // addr 1 votes
        vm.prank(playerOne);
        govImpl.castVote(proposalId, 1);

        // expect revert
        vm.prank(playerTwo);
        vm.expectRevert(TokenLocked.selector);
        // addr 2 unstakes
        frankenpunks.unstake(ids[1], playerTwo);
     }

    // reverts if delegating during a vote
    // function testLocking__RevertsIfDelegatingDuringVoting() public {
        // addr 1 stakes
        // addr 2 stakes
        // addr 2 delegates to addr 1
        // create proposal
        // addr 1 votes
        // addr 2 delegates back to themselves
        // expect revert
    // }
}
