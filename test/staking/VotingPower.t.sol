pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { StakingBase } from "./StakingBase.t.sol";
import { IERC721 } from "../../src/interfaces/IERC721.sol";

contract VotingPowerTest is StakingBase {
    uint FAKE_ID = 12;

    // Test that staking, delegating, and undelegating all adjust voting power.
    function testStakingVP__UndelegatingUpdatesVotingPower() public {
        address staker = frankenpunks.ownerOf(FAKE_ID);
        assert(staking.getVotes(staker) == 0);        

        address owner = mockStakeSingle(FAKE_ID);
        assert(owner == staker);

        uint evilBonus = staking.evilBonus(FAKE_ID);

        assert(staking.getVotes(staker) == 20 + evilBonus);

        vm.prank(staker);
        staking.delegate(address(1));

        assert(staking.getVotes(staker) == 0);

        vm.prank(staker);
        staking.delegate(address(0));

        assert(staking.getVotes(staker) == 20 + evilBonus);
    }

    // Test that unstaking reduces voting power.
    function testStakingVP__UnstakingReducesVotingPower() public {
        address staker = frankenpunks.ownerOf(FAKE_ID);
        assert(staking.getVotes(staker) == 0);        

        address owner = mockStakeSingle(FAKE_ID);
        assert(owner == staker);

        uint evilBonus = staking.evilBonus(FAKE_ID);

        assert(staking.getVotes(staker) == 20 + evilBonus);

        mockUnstakeSingle(FAKE_ID);

        assert(staking.getVotes(staker) == 0);
    }
}
