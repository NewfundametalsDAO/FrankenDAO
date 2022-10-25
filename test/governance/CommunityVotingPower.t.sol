pragma solidity ^0.8.13;

import "./GovernanceBase.t.sol";

contract CommunityVotingPower is GovernanceBase {
    // ----
    // Multipliers
    // ----
    // new votes multiplier changes individual community voting power
    function testCommunityVP__NewVotesMultiplierChangesIndividualCommunityVP()
        public
    {
        address user = mockStakeSingle(1000);
        uint proposalId = _createAndVerifyProposal();

        // @todo switch this to warp when switching to times
        vm.roll(block.number + gov.votingDelay());

        vm.prank(user);
        gov.castVote(proposalId, 1);

        uint initialCommunityVP = staking.getCommunityVotingPower(user);

        vm.prank(address( executor ));
        staking.setVotesMultiplier(200);

        uint256 finalCommunityVP = staking.getCommunityVotingPower(user);

        assertEq(finalCommunityVP, initialCommunityVP * 2);

        vm.prank(address( executor ));
        staking.setVotesMultiplier(100);

        finalCommunityVP = staking.getCommunityVotingPower(user);
        assertEq(finalCommunityVP, initialCommunityVP);
    }
    // new proposals multiplier changes individual community voting power
    function testCommunityVP__NewProposalsMultiplierChangesIndividualCommunityVP()
        public
    {
        uint proposalId = _createAndExecuteSuccessfulProposal();

        uint initialCommunityVP = staking.getCommunityVotingPower(proposer);

        vm.prank(address( executor ));
        staking.setProposalsCreatedMultiplier(400);

        uint256 finalCommunityVP = staking.getCommunityVotingPower(proposer);

        assert(finalCommunityVP > initialCommunityVP);

        vm.prank(address( executor ));
        staking.setProposalsCreatedMultiplier(200);

        finalCommunityVP = staking.getCommunityVotingPower(proposer);

        assertEq(finalCommunityVP, initialCommunityVP);
    }
    // new executed/passed proposals multiplier changes individual community voting power
    function testCommunityVP__NewExecutedProposalsMultiplierChangesIndividualCommunityVP()
        public
    {
        uint proposalId = _createAndExecuteSuccessfulProposal();

        uint initialCommunityVP = staking.getCommunityVotingPower(proposer);

        vm.prank(address( executor ));
        staking.setProposalsPassedMultiplier(400);

        uint256 finalCommunityVP = staking.getCommunityVotingPower(proposer);

        assert(finalCommunityVP > initialCommunityVP);

        vm.prank(address( executor ));
        staking.setProposalsPassedMultiplier(200);

        finalCommunityVP = staking.getCommunityVotingPower(proposer);

        assertEq(finalCommunityVP, initialCommunityVP);
    }

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
    function testCommunityVP__ProposingIncreasesTotalVotingPower() public {
        uint initialTotalVP = staking.getTotalVotingPower();

        _createAndVerifyProposal();

        uint finalTotalVP = staking.getTotalVotingPower();

        assert(finalTotalVP > initialTotalVP);
    }
    // voting increases total community voting power
    function testCommunityVP__VotingIncreasesTotalVotingPower() public {
        uint initialTotalVP = staking.getTotalVotingPower();

        uint proposalID = _createAndVerifyProposal();

        // @todo switch this to warp when switching to times
        vm.roll(block.number + gov.votingDelay());

        vm.prank(voter);
        gov.castVote(proposalID, 1);

        uint finalTotalVP = staking.getTotalVotingPower();

        assert(finalTotalVP > initialTotalVP);
    }
    // proposal passing increases total community voting power
    function testCommunityVP__ProposalPassingIncreasesTotalVotingPower()
        public
    {
        uint initialTotalVP = staking.getTotalVotingPower();

        uint proposalID = _createAndVerifyProposal();

        // @todo switch this to warp when switching to times
        vm.roll(block.number + gov.votingDelay());

        vm.prank(voter);
        gov.castVote(proposalID, 1);

        // @todo switch this to warp when switching to times
        vm.roll(block.number + gov.votingPeriod() + 1);

        vm.prank(COUNCIL_MULTISIG);
        gov.queue(proposalID);

        vm.warp(block.timestamp + executor.DELAY());

        vm.prank(COUNCIL_MULTISIG);
        gov.execute(proposalID);

        uint finalTotalVP = staking.getTotalVotingPower();

        assert(finalTotalVP > initialTotalVP);
    }
}
