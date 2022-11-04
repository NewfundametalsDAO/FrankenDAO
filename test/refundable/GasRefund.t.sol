pragma solidity ^0.8.13;

import { GovernanceBase } from "../bases/GovernanceBase.t.sol";
import { IGovernance } from "../../src/interfaces/IGovernance.sol";
import "forge-std/Test.sol";

contract GasRefundTests is GovernanceBase {

    //////////////////////////
    //// REFUNDING WORKS /////
    //////////////////////////

    // Test that gas refunding succeeds at a reasonable number for staking.
    function testGasRefund__StakingRefundsGas() public {
        address owner = frankenpunks.ownerOf(PUNK_ID);

        uint stakingBal = address(staking).balance;
        uint ownerBal = owner.balance;

        uint[] memory ids = new uint[](1);
        ids[0] = PUNK_ID;
        vm.startPrank(owner);
        frankenpunks.approve(address(staking), PUNK_ID);
        staking.stake(ids, 0);
        vm.stopPrank();

        // This means approx 160-320k gas refunded = 4-8mm gwei
        assert(_refundInRange(address(staking), stakingBal, owner, ownerBal, 0.004 ether, 0.008 ether));
    }

    // Test that gas refunding succeeds at a reasonable number for delegating.
    function testGasRefund__DelegatingRefundsGas() public {
        address owner = mockStakeSingle(PUNK_ID);

        uint stakingBal = address(staking).balance;
        uint ownerBal = owner.balance;

        vm.prank(owner);
        staking.delegate(makeAddr("randomDelegate"));

        // This means approx 40-100k gas refunded = 1-2.5mm gwei
        assert(_refundInRange(address(staking), stakingBal, owner, ownerBal, 0.001 ether, 0.025 ether));
    }

    // Test that gas refunding succeeds at a reasonable number for proposing.
    function testGasRefund__ProposingRefundsGas() public {
        uint govBal = address(gov).balance;
        uint proposerBal = proposer.balance;

        _createProposal();

        // This means approx 300-400k gas refunded = 7.5-10mm wei
        assert(_refundInRange(address(gov), govBal, proposer, proposerBal, 0.0075 ether, 0.01 ether));
    }

    // Test that gas refunding succeeeds at a reasonable number for voting.
    function testGasRefund__VotingRefundsGas() public {
        uint proposalId = _createAndVerifyProposal();
        vm.warp(block.timestamp + gov.votingDelay());

        uint govBal = address(gov).balance;
        uint voterBal = voter.balance;

        vm.prank(voter);
        gov.castVote(proposalId, 1);

        // This means approx 40-100k gas refunded = 1-2.5mm gwei
        assert(_refundInRange(address(gov), govBal, voter, voterBal, 0.001 ether, 0.0025 ether));
    }

    //////////////////////////
    /// BALANCE RUNNING OUT //
    //////////////////////////

    // Test that gas refunding reverts if the contract has no funds and refunds are on.
    function testGasRefund__StakingRevertsIfRefundsOnAndNoBalance() public {
        vm.prank(address(staking));
        payable(address(0)).transfer(address(staking).balance);

        vm.expectRevert(InsufficientRefundBalance.selector);
        vm.prank(proposer);
        staking.delegate(makeAddr("randomDelegate"));

        vm.prank(address(gov));
        payable(address(0)).transfer(address(gov).balance);

        vm.expectRevert(InsufficientRefundBalance.selector);
        _createProposal();
    }

    // Test that if staking refunding is turned off, we can stake and it doesn't refund (and is fine with no funds).
    function testGasRefund__StakingOffNoBalanceOk() public {
        vm.prank(address(executor));
        staking.setRefunds(false, true);

        vm.prank(address(staking));
        payable(address(0)).transfer(address(staking).balance);

        uint stakingBal = address(staking).balance;
        address owner = _mockStakeSingle(100, 0);

        assert(address(staking).balance == stakingBal);
        assert(stakingBal == 0);
    }

   // Test that if delegating refunding is turned off, we can delegate and it doesn't refund (and is fine with no funds).
    function testGasRefund__DelegatingOffNoBalanceOk() public {
        vm.prank(address(executor));
        staking.setRefunds(true, false);

        vm.prank(address(staking));
        payable(address(0)).transfer(address(staking).balance);
        uint stakingBal = address(staking).balance;

        vm.prank(proposer);
        staking.delegate(makeAddr("randomDelegate"));

        assert(address(staking).balance == stakingBal);
        assert(stakingBal == 0);
    }

    // Test that governance reverts if refunding is on but has no balance.
    function testGasRefund__GovernanceRevertsIfRefundsOnAndNoBalance() public {
        vm.prank(address(gov));
        payable(address(0)).transfer(address(gov).balance);

        vm.expectRevert(InsufficientRefundBalance.selector);
        _createProposal();
    }

    // Test that if proposal refunding is turned off, we can propose and it doesn't refund (and is fine with no funds).
    function testGasRefund__ProposingOffNoBalanceOk() public {
        vm.prank(address(executor));
        gov.setRefunds(true, false);

        vm.prank(address(gov));
        payable(address(0)).transfer(address(gov).balance);

        uint govBal = address(gov).balance;
        _createProposal();

        assert(address(gov).balance == govBal);
        assert(govBal == 0);
    }

    // Test that if voting refunding is turned off, we can vote and it doesn't refund (and is fine with no funds).
    function testGasRefund__VotingOffNoBalanceOk() public {
        uint proposalId = _createAndVerifyProposal();
        vm.warp(block.timestamp + gov.votingDelay());

        vm.prank(address(executor));
        gov.setRefunds(false, true);

        vm.prank(address(gov));
        payable(address(0)).transfer(address(gov).balance);

        uint govBal = address(gov).balance;
        vm.prank(voter);
        gov.castVote(proposalId, 1);

        assert(address(gov).balance == govBal);
        assert(govBal == 0);
    }

    //////////////////////////
    /////// ON AND OFF ///////
    //////////////////////////

    // Test that refunding works correctly if staking is on but delegating is off.
    function testGasRefund__StakingOnDelegatingOff() public {
        vm.prank(address(executor));
        staking.setRefunds(true, false);

        uint stakingBal1 = address(staking).balance;
        address owner = _mockStakeSingle(100, 0);
        uint stakingBal2 = address(staking).balance;

        vm.prank(owner);
        staking.delegate(makeAddr("randomDelegate"));

        assert(address(staking).balance == stakingBal2);
        assert(stakingBal1 > stakingBal2);
    }

    // Test that refunding works correctly if staking is off but delegating is on.
    function testGasRefund__StakingOffDelegatingOn() public {
        vm.prank(address(executor));
        staking.setRefunds(false, true);

        uint stakingBal1 = address(staking).balance;
        address owner = _mockStakeSingle(100, 0);
        uint stakingBal2 = address(staking).balance;

        vm.prank(owner);
        staking.delegate(makeAddr("randomDelegate"));

        assert(address(staking).balance < stakingBal2);
        assert(stakingBal1 == stakingBal2);
    }

    // Test that refunding works correctly if proposing is on but voting is off.
    function testGasRefund__ProposingOnVotingOff() public {
        vm.prank(address(executor));
        gov.setRefunds(false, true);

        uint govBal1 = address(gov).balance;

        uint proposalId = _createAndVerifyProposal();
        vm.warp(block.timestamp + gov.votingDelay());


        uint govBal2 = address(gov).balance;
        vm.prank(voter);
        gov.castVote(proposalId, 1);

        assert(address(gov).balance == govBal2);
        assert(govBal1 > govBal2);
    }

    // Test that refunding works correctly if proposing is off but voting is on.
    function testGasRefund__ProposingOffVotingOn() public {
        vm.prank(address(executor));
        gov.setRefunds(true, false);

        uint govBal1 = address(gov).balance;

        uint proposalId = _createAndVerifyProposal();
        vm.warp(block.timestamp + gov.votingDelay());

        uint govBal2 = address(gov).balance;
        vm.prank(voter);
        gov.castVote(proposalId, 1);

        assert(address(gov).balance < govBal2);
        assert(govBal1 == govBal2);
    }

    //////////////////////////
    //////// INTERNAL ////////
    //////////////////////////

    function _refundInRange(
        address _refunder, 
        uint _refunderStartBal,
        address _refundee, 
        uint _refundeeStartBal,
        uint _minRefund, 
        uint _maxRefund
    ) internal returns (bool) {

        // Forge tests don't consume gas from account balances, so just make sure transfer was reasonable.
        return (
            _refunderStartBal - _refunder.balance < _maxRefund && 
            _refunderStartBal - _refunder.balance > _minRefund &&
            _refundee.balance - _refundeeStartBal == _refunderStartBal - _refunder.balance
        );
    }
}