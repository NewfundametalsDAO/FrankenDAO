pragma solidity ^0.8.13;

import "./GovernanceBase.t.sol";

contract CommunityVotingPower is GovernanceBase {
    // ----
    // Individual Community Voting Power
    // ----
    // proposing doesn't increase my community voting power if proposal doesn't get verified
    function testCommunityVP__ProposingDoesntAffectVPIfProposalNotVerified()
        public
    {
        address user = mockStakeSingle(1000);

        uint256 initialCommunityVP = staking.getCommunityVotingPower(user);

        (
            address[] memory targets,
            uint256[] memory values,
            string[] memory sigs,
            bytes[] memory calldatas
        ) = _generateFakeProposalData();

        uint256 finalCommunityVP = staking.getCommunityVotingPower(user);

        assertEq(initialCommunityVP, finalCommunityVP);
    }

    // proposing increases my community voting power after verified
    function testCommunityVP__ProposingIncreasesMyCommunityVP() public {
        address user = mockStakeSingle(1000);

        uint256 initialCommunityVP = staking.getCommunityVotingPower(user);

        (
            address[] memory targets,
            uint256[] memory values,
            string[] memory sigs,
            bytes[] memory calldatas
        ) = _generateFakeProposalData();

        vm.prank(user);
        uint256 proposalId = gov.propose(
            targets,
            values,
            sigs,
            calldatas,
            "test"
        );

        // @todo switch this to warp when switching to times
        vm.roll(block.number + gov.votingDelay());

        vm.prank(COUNCIL_MULTISIG);
        gov.verifyProposal(proposalId);

        uint256 finalCommunityVP = staking.getCommunityVotingPower(user);

        assert(finalCommunityVP > initialCommunityVP);
    }
    // voting increases my community voting power
    function testCommunityVP__VotingIncreasesCommunityVP() public {
        address user = mockStakeSingle(1000);

        uint256 initialCommunityVP = staking.getCommunityVotingPower(user);

        uint proposalID = _createAndVerifyProposal();

        // @todo switch this to warp when switching to times
        vm.roll(block.number + gov.votingDelay());

        vm.prank(user);
        gov.castVote(proposalID, 1);

        uint256 finalCommunityVP = staking.getCommunityVotingPower(user);

        assert(finalCommunityVP > initialCommunityVP);
    }
    // proposal passing increases my community voting power
    function testCommunityVP__ProposalPassingIncreasesMyCommunityVP() public {
        address user = mockStakeSingle(1000);

        uint256 initialCommunityVP = staking.getCommunityVotingPower(user);

        (
            address[] memory targets,
            uint256[] memory values,
            string[] memory sigs,
            bytes[] memory calldatas
        ) = _generateFakeProposalData();

        vm.prank(user);
        uint256 proposalId = gov.propose(
            targets,
            values,
            sigs,
            calldatas,
            "test"
        );

        // @todo switch this to warp when switching to times
        vm.roll(block.number + gov.votingDelay());

        vm.prank(COUNCIL_MULTISIG);
        gov.verifyProposal(proposalId);

        vm.prank(voter);
        gov.castVote(proposalId, 1);

        // @todo switch this to warp when switching to times
        vm.roll(block.number + gov.votingPeriod() + 1);

        vm.prank(COUNCIL_MULTISIG);
        gov.queue(proposalId);

        vm.warp(block.timestamp + executor.DELAY());

        vm.prank(COUNCIL_MULTISIG);
        gov.execute(proposalId);

        uint256 finalCommunityVP = staking.getCommunityVotingPower(user);

        assert(finalCommunityVP > initialCommunityVP);
    }

    // ----
    // Total Community Voting Power
    // ----
    // delegating doesn't affect total community voting power
    function testCommunityVP__DelegatingDoesntAffectTotalCommunityVP() public {
        address user = mockStakeSingle(1000);
        address delegate = mockStakeSingle(420);

        uint256 initialTotalVP = staking.getTotalVotingPower();

        vm.prank(user);
        staking.delegate(delegate);

        uint256 finalTotalVP = staking.getTotalVotingPower();

        assertEq(initialTotalVP, finalTotalVP);
    }
    // proposing increases total community voting power
    //function testCommunityVP__ProposingIncreasesTotalVotingPower() public {
        //uint initialTotalVP = staking.getTotalVotingPower();

        //_createAndVerifyProposal();

        //uint finalTotalVP = staking.getTotalVotingPower();

        //assertEq(finalTotalVP, initialTotalVP + 1);
    //}
    // voting increases total community voting power
    // proposal passing increases total community voting power
}
