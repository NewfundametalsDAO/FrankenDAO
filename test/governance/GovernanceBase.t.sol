pragma solidity ^0.8.13;

import { StakingBase } from "../staking/StakingBase.t.sol";
import { IERC721 } from "../../src/interfaces/IERC721.sol";

contract GovernanceBase is StakingBase {
    address proposer;
    uint PROPOSER_TOKEN_ID = 0;    
    address voter;
    uint VOTER_TOKEN_ID = 10;

    /// @notice Possible states that a proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed,
        Vetoed
    }

    function setUp() public override {
        super.setUp();
        
        proposer = mockStakeSingle(PROPOSER_TOKEN_ID, 0);
        voter = mockStakeSingle(VOTER_TOKEN_ID, block.timestamp + 4 weeks);
    }

    function _generateFakeProposalData() public returns (
        address[] memory,
        uint[] memory,
        string[] memory,
        bytes[] memory
    ) {
        address[] memory targets = new address[](1);
        targets[0] = FRANKENPUNKS;

        uint[] memory values = new uint[](1);
        values[0] = 0;

        string[] memory sigs = new string[](1);
        sigs[0] = "ownerOf(uin256)";
        
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encode(0);

        return (targets, values, sigs, calldatas);
    }
}