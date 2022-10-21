pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { StakingBase } from "../staking/StakingBase.t.sol";
import { IERC721 } from "../../src/interfaces/IERC721.sol";
import { IGovernance } from "../../src/interfaces/IGovernance.sol";

contract GovernanceBase is StakingBase {
    address proposer;
    uint[] VOTER_TOKEN_IDS = [0, 1, 2]; 
    address voter;
    uint PROPOSER_TOKEN_ID = 10;
    address stranger = _generateAddress("stranger");

    function setUp() public override {
        super.setUp();

        proposer = mockStakeSingle(PROPOSER_TOKEN_ID, 0);
        
        uint[] memory tokenIds = new uint[](3);
        for (uint i = 0; i < 3; i++) {
            tokenIds[i] = VOTER_TOKEN_IDS[i];
            voter = mockStakeSingle(tokenIds[i], block.timestamp + 4 weeks);
        }
    }

    function _generateFakeProposalData() public view returns (
        address[] memory,
        uint[] memory,
        string[] memory,
        bytes[] memory
    ) {
        address[] memory targets = new address[](1);
        targets[0] = address(gov);

        uint[] memory values = new uint[](1);
        values[0] = 0;

        string[] memory sigs = new string[](1);
        sigs[0] = "setVotingPeriod(uint256)";
        
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encode(6 days);

        return (targets, values, sigs, calldatas);
    }

    function _getTxHash(
        address target, 
        uint value, 
        string memory sig, 
        bytes memory data, 
        uint eta
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(target, value, sig, data, eta));
    }

    function _checkState(uint proposalId, IGovernance.ProposalState targetState) internal view returns (bool) {
        IGovernance.ProposalState proposalState = gov.state(proposalId);
        return proposalState == targetState;
    }

    function _createProposal() public returns (uint) {
        (
            address[] memory targets, 
            uint[] memory values, 
            string[] memory sigs, 
            bytes[] memory calldatas
        ) = _generateFakeProposalData();

        vm.prank(proposer);
        return gov.propose(targets, values, sigs, calldatas, "test");
    }

    function _createAndVerifyProposal() public returns (uint) {
        uint proposalId = _createProposal();
        vm.prank(COUNCIL_MULTISIG);
        gov.verifyProposal(proposalId);
        return proposalId;
    }

    function _createSuccessfulProposal() public returns (uint) {
        uint proposalId = _createAndVerifyProposal();

        // @todo switch this to warp when switching to times
        vm.roll(block.number + gov.votingDelay());

        _vote(proposalId, 1, true); // voter votes for proposal

        // @todo switch this to warp when switching to times
        vm.roll(block.number + gov.votingPeriod() + 1);

        return proposalId;
    }

    function _vote(uint proposalId, uint8 voterVote, bool voterVotes) internal {
        vm.prank(proposer);
        gov.castVote(proposalId, 1);
        if (voterVotes) {
            vm.prank(voter);
            gov.castVote(proposalId, voterVote);
        }
    }
}