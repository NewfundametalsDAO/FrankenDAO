// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./interfaces/IGovernance.sol";
import "./Staking.sol";
import "./Executor.sol";
import "./utils/Admin.sol";
import "./utils/Refund.sol";

contract Governance is IGovernance, Admin, Refund {
    bool public initialized;

       /// @notice The name of this contract
    string public constant name = "Franken DAO";

    /// @notice The address of staked the Franken tokens
    Staking public staking;

    //////////////////////////
    //// Voting Constants ////
    //////////////////////////

    /// @notice The minimum setable proposal threshold
    uint256 public constant MIN_PROPOSAL_THRESHOLD_BPS = 1; // 1 basis point or 0.01%

    /// @notice The maximum setable proposal threshold
    uint256 public constant MAX_PROPOSAL_THRESHOLD_BPS = 1_000; // 1,000 basis points or 10%

    /// @notice The minimum setable voting period
    uint256 public constant MIN_VOTING_PERIOD = 5_760; // About 24 hours

    /// @notice The max setable voting period
    uint256 public constant MAX_VOTING_PERIOD = 80_640; // About 2 weeks

    /// @notice The min setable voting delay
    uint256 public constant MIN_VOTING_DELAY = 1;

    /// @notice The max setable voting delay
    uint256 public constant MAX_VOTING_DELAY = 40_320; // About 1 week

    /// @notice The minimum setable quorum votes basis points
    uint256 public constant MIN_QUORUM_VOTES_BPS = 200; // 200 basis points or 2%

    /// @notice The maximum setable quorum votes basis points
    uint256 public constant MAX_QUORUM_VOTES_BPS = 2_000; // 2,000 basis points or 20%

    /// @notice The maximum number of actions that can be included in a proposal
    uint256 public constant PROPOSAL_MAX_OPERATIONS = 10; // 10 actions

    ///////////////////////////
    //// Voting Parameters ////
    ///////////////////////////

    /// @notice The delay before voting on a proposal may take place, once proposed, in blocks
    uint256 public votingDelay;

    /// @notice The duration of voting on a proposal, in blocks
    uint256 public votingPeriod;

    /// @notice The basis point number of votes required in order for a voter to become a proposer. *DIFFERS from GovernerBravo
    uint256 public proposalThresholdBPS;

    /// @notice The basis point number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed. *DIFFERS from GovernerBravo
    uint256 public quorumVotesBPS;

    /// @notice Whether or not gas is refunded for casting votes.
    bool public votingRefund;

    /// @notice Whether or not gas is refunded for submitting proposals.
    bool public proposalRefund;

    //////////////////
    //// Proposal ////
    //////////////////

    /// @notice The total number of proposals
    uint256 public proposalCount;

    /// @notice The official record of all proposals ever proposed
    mapping(uint256 => Proposal) public proposals;

    uint256[] public activeProposals;

    /// @notice The latest proposal for each proposer
    mapping(address => uint256) public latestProposalIds;

    mapping(address => CommunityScoreData) public userCommunityScoreData;
    // note: this is only the data that is currently live, if a user is delegates / unstaked it's removed from here (but still counted above)
    CommunityScoreData public totalCommunityScoreData;


    /**
     * @notice Used to initialize the contract during delegator contructor
     * @param executor_ The address of the FrankenDAOExecutor
     * @param staking_ The address of the staked FrankenPunks tokens
     * @param founders_ The address of the founder's multi-sig
     * @param council_ The address of the council's multi-sig
     * @param votingPeriod_ The initial voting period
     * @param votingDelay_ The initial voting delay
     * @param proposalThresholdBPS_ The initial proposal threshold in basis points
     * * @param quorumVotesBPS_ The initial quorum votes threshold in basis points
     */
    function initialize(
        address payable executor_,
        address staking_,
        address founders_,
        address council_,
        uint256 votingPeriod_,
        uint256 votingDelay_,
        uint256 proposalThresholdBPS_,
        uint256 quorumVotesBPS_
    ) public virtual {
        require(!initialized, "FrankenDAOExecutor::initialize:already initialized");
        require(executor_ != address(0),"FrankenDAO::initialize: invalid executor address");
        require(staking_ != address(0),"FrankenDAO::initialize: invalid staking address");
        require(votingPeriod_ >= MIN_VOTING_PERIOD && votingPeriod_ <= MAX_VOTING_PERIOD, "FrankenDAO::initialize: invalid voting period");
        require(votingDelay_ >= MIN_VOTING_DELAY && votingDelay_ <= MAX_VOTING_DELAY, "FrankenDAO::initialize: invalid voting delay");
        require(proposalThresholdBPS_ >= MIN_PROPOSAL_THRESHOLD_BPS && proposalThresholdBPS_ <= MAX_PROPOSAL_THRESHOLD_BPS, "FrankenDAO::initialize: invalid proposal threshold" );
        require(quorumVotesBPS_ >= MIN_QUORUM_VOTES_BPS && quorumVotesBPS_ <= MAX_QUORUM_VOTES_BPS, "FrankenDAO::initialize: invalid proposal threshold" );

        emit VotingPeriodSet(votingPeriod, votingPeriod_);
        emit VotingDelaySet(votingDelay, votingDelay_);
        emit ProposalThresholdBPSSet( proposalThresholdBPS, proposalThresholdBPS_ );
        emit QuorumVotesBPSSet(quorumVotesBPS, quorumVotesBPS_);

        staking = Staking(staking_);
        votingPeriod = votingPeriod_;
        votingDelay = votingDelay_;
        proposalThresholdBPS = proposalThresholdBPS_;
        quorumVotesBPS = quorumVotesBPS_;

        executor = Executor(executor_);
        founders = founders_;
        council = council_;

        initialized = true;
    }

    ///////////////
    //// Views ////
    ///////////////
    /**
     * @notice Gets actions of a proposal
     * @param proposalId the id of the proposal
     * @return targets
     * @return values
     * @return signatures
     * @return calldatas
     */
    function getActions(uint256 proposalId) external view returns (
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas
    ) {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    function getProposalData(uint256 id_) public view returns (uint256, address, uint256, uint256) {
        Proposal storage proposal = proposals[id_];
        return (proposal.id, proposal.proposer, proposal.proposalThreshold, proposal.quorumVotes);
    }

    /// @notice get the status of a proposal
    function getProposalStatus(uint256 id_) public view returns (bool, bool, bool) {
        Proposal storage proposal = proposals[id_];
        return (proposal.canceled, proposal.vetoed, proposal.executed);
    }

    function getProposalVotes(uint256 id_) public view returns (uint256, uint256, uint256) {
        Proposal storage proposal = proposals[id_];
        return (proposal.forVotes, proposal.againstVotes, proposal.abstainVotes);
    }

    /**
     * @notice Gets the receipt for a voter on a given proposal
     * @param proposalId the id of proposal
     * @param voter The address of the voter
     * @return The voting receipt
     */
    function getReceipt(uint256 proposalId, address voter) external view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    /**
     * @notice Gets the state of a proposal
     * @param proposalId The id of the proposal
     * @return Proposal state
     */
    function state(uint256 proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId, "FrankenDAO::state: invalid proposal id");
        Proposal memory proposal = proposals[proposalId];
        if (proposal.vetoed) {
            return ProposalState.Vetoed;
        } else if (proposal.canceled || (!proposal.verified && block.number > proposal.endBlock)) {
            return ProposalState.Canceled;
        }  else if (block.number <= proposal.startBlock || !proposal.verified) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < proposal.quorumVotes) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= proposal.eta + executor.GRACE_PERIOD()) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    /**
     * @notice Current proposal threshold using Noun Total Supply
     * Differs from `GovernerBravo` which uses fixed amount
     */
    function proposalThreshold() public view returns (uint256) {
        return bps2Uint(proposalThresholdBPS, staking.getTotalVotingPower());
    }

    /**
     * @notice Current quorum votes using Noun Total Supply
     * Differs from `GovernerBravo` which uses fixed amount
     */
    function quorumVotes() public view returns (uint256) {
        return bps2Uint(quorumVotesBPS, staking.getTotalVotingPower());
    }

    function bps2Uint(uint256 bps, uint256 number) internal pure returns (uint256) {
        return (number * bps) / 10000;
    }

    ///////////////////
    //// Proposals ////
    ///////////////////

    /**
     * @notice Function used to propose a new proposal. Sender must have delegates above the proposal threshold
     * @param targets Target addresses for proposal calls
     * @param values Eth values for proposal calls
     * @param signatures Function signatures for proposal calls
     * @param calldatas Calldatas for proposal calls
     * @param description String description of the proposal
     * @return Proposal id of new proposal
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) public returns (uint256) {
        uint256 proposalId = _propose(targets, values, signatures, calldatas, description);
        return proposalId;
    }

    function proposeWithRefund(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) public refundable returns (uint256) {
        require(proposalRefund, "FrankenDAO::proposeWithRefund: refunding gas is turned off");
        uint256 proposalId = _propose(targets, values, signatures, calldatas, description);
        return proposalId;
    }

    function _propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) internal returns (uint256) {
        ProposalTemp memory temp;

        temp.totalSupply = staking.getTotalVotingPower();
        temp.proposalThreshold = bps2Uint(proposalThresholdBPS, temp.totalSupply);
        require(staking.getVotes(msg.sender) > temp.proposalThreshold,
            "FrankenDAO::propose: proposer votes below proposal threshold"
        );

        require(targets.length != 0, "FrankenDAO::propose: must provide actions");
        require(targets.length <= PROPOSAL_MAX_OPERATIONS, "FrankenDAO::propose: too many actions");
        require(
            targets.length == values.length &&
            targets.length == signatures.length &&
            targets.length == calldatas.length,
            "FrankenDAO::propose: proposal function information arity mismatch"
        );

        temp.latestProposalId = latestProposalIds[msg.sender];
        if (temp.latestProposalId != 0) {
            ProposalState proposersLatestProposalState = state(temp.latestProposalId);
            require(
                proposersLatestProposalState != ProposalState.Active && proposersLatestProposalState != ProposalState.Pending,
                "FrankenDAO::propose: one active / pending proposal per proposer"
            );
        }

        temp.startBlock = block.number + votingDelay;
        temp.endBlock = temp.startBlock + votingPeriod;

        Proposal storage newProposal = proposals[++proposalCount];

        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.proposalThreshold = temp.proposalThreshold;
        newProposal.quorumVotes = bps2Uint(quorumVotesBPS, temp.totalSupply);
        newProposal.eta = 0;
        newProposal.targets = targets;
        newProposal.values = values;
        newProposal.signatures = signatures;
        newProposal.calldatas = calldatas;
        newProposal.startBlock = temp.startBlock;
        newProposal.endBlock = temp.endBlock;
        newProposal.forVotes = 0;
        newProposal.againstVotes = 0;
        newProposal.abstainVotes = 0;
        newProposal.verified = false;
        newProposal.canceled = false;
        newProposal.executed = false;
        newProposal.vetoed = false;

        latestProposalIds[newProposal.proposer] = newProposal.id;
        activeProposals.push(_id);

        /// @notice Updated event with `proposalThreshold` and `quorumVotes`
        emit ProposalCreatedWithRequirements(
            newProposal.id,
            msg.sender,
            targets,
            values,
            signatures,
            calldatas,
            newProposal.startBlock,
            newProposal.endBlock,
            newProposal.proposalThreshold,
            newProposal.quorumVotes,
            description
        );

        return newProposal.id;
    }

    /// @notice Function for verifying a proposal
    /// @param _id Id of the proposal to verify
    function verifyProposal(uint _proposalId) external onlyVetoers {
        // Can't verify a proposal that's been vetoed, canceled,
        require(
            state(_proposalId) == ProposalState.Pending,
            "FrankenDAOGovernance::verifyProposal: proposal must be pending to be verified"
        );

        Proposal proposal = proposals[_proposalId];

        // verify proposal
        proposal.verified = true;

        // update community score data
        uint256 userProposalCount = ++userCommunityScoreData[proposal.proposer].proposalsCreated;
        // we can do this with no check because if you can propose, it means you have votes so you haven't delegated
        totalCommunityScoreData.proposalsCreated += 1;
    }

    /////////////////
    //// Execute ////
    /////////////////
    /**
     * @notice Queues a proposal of state succeeded
     * @param proposalId The id of the proposal to queue
     */
    function queue(uint256 proposalId) external {
        require(
            state(proposalId) == ProposalState.Succeeded,
            "FrankenDAO::queue: proposal can only be queued if it is succeeded"
        );
        Proposal storage proposal = proposals[proposalId];
        uint256 eta = block.timestamp + executor.delay();
        uint numTargets = proposal.targets.length;
        for (uint256 i = 0; i < numTargets; i++) {
            queueOrRevertInternal(
                proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta
            );
        }
        proposal.eta = eta;

        _removeFromActiveProposals(proposalId);

        emit ProposalQueued(proposalId, eta);
    }

    function queueOrRevertInternal(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) internal {
        require(!executor.queuedTransactions(keccak256(abi.encode(target, value, signature, data, eta))),
            "FrankenDAO::queueOrRevertInternal: identical proposal action already queued at eta"
        );
        executor.queueTransaction(target, value, signature, data, eta);
    }

    /**
     * @notice Executes a queued proposal if eta has passed
     * @param proposalId The id of the proposal to execute
     */
    function execute(uint256 proposalId) external {
        require(
            state(proposalId) == ProposalState.Queued,
            "FrankenDAO::execute: proposal can only be executed if it is queued"
        );
        Proposal storage proposal = proposals[proposalId];

        uint256 userSuccessfulProposalCount = ++userCommunityScoreData[proposal.proposer].proposalsPassed;
        // we can do this with no check because if you can propose, it means you have votes so you haven't delegated
        totalCommunityScoreData.proposalsPassed += 1;
        
        proposal.executed = true;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            executor.executeTransaction(
                proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta
            );
        }
        emit ProposalExecuted(proposalId);
    }

    ////////////////////////////////
    //// Cancel / Veto Proposal ////
    ////////////////////////////////
    /**
     * @notice Cancels a proposal only if sender is the proposer, or proposer delegates dropped below proposal threshold
     * @param proposalId The id of the proposal to cancel
     */
    function cancel(uint256 proposalId) external {
        Proposal memory proposal = proposals[proposalId];
        require(
            !proposal.executed && !proposal.canceled && !proposal.vetoed,
            "FrankenDAO::cancel: cannot cancel executed, vetoed, or canceled proposal"
        );

        require(
            msg.sender == proposal.proposer ||
            staking.getVotes(proposal.proposer) < proposal.proposalThreshold ||
            !proposal.verified && block.number > proposal.endBlock || 
            state(proposalId) == ProposalState.Expired,
            "FrankenDAO::cancel: cancel requirements not met"
        );

        _removeTransactionIfQueued(proposal);

        proposals[proposalId].canceled = true;        

        emit ProposalCanceled(proposalId);
    }

    /**
     * @notice Vetoes a proposal only if sender has ability to veto a proposal
     * @param proposalId The id of the proposal to veto
     */
    function veto(uint256 proposalId) external onlyVetoers {
        Proposal memory proposal = proposals[proposalId];
        require(
            !proposal.executed && !proposal.canceled && !proposal.vetoed,
            "FrankenDAO::veto: cannot veto executed, vetoed, or canceled proposal"
        );

        _removeTransactionIfQueuedOrExpired(proposal);

        proposals[proposalId].vetoed = true;

        emit ProposalVetoed(proposalId);
    }

    function _removeTransactionIfQueuedOrExpired(Proposal memory proposal) internal {
        if (
            state(proposal.id) == ProposalState.Queued || 
            state(proposal.id) == ProposalState.Expired
        ) {
            for (uint256 i = 0; i < proposal.targets.length; i++) {
                executor.cancelTransaction(
                    proposal.targets[i],
                    proposal.values[i],
                    proposal.signatures[i],
                    proposal.calldatas[i],
                    proposal.eta
                );
            }
        } else {
            _removeFromActiveProposals(proposal.id);
        }
    }

    ////////////////
    //// Voting ////
    ////////////////
    /**
     * @notice Cast a vote for a proposal
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain
     */
    function castVote(uint256 proposalId, uint8 support) external {
        emit VoteCast( 
            msg.sender, proposalId, support, castVoteInternal(msg.sender, proposalId, support) 
        );
    }

    /**
     * @notice Cast a vote for a proposal, asking the DAO to refund gas costs.
     * Users with > 0 votes receive refunds. Refunds are partial when using a gas priority fee higher than the DAO's cap.
     * Refunds are partial when the DAO's balance is insufficient.
     * No refund is sent when the DAO's balance is empty. No refund is sent to users with no votes.
     * Voting takes place regardless of refund success.
     * @param proposalId_ The id of the proposal to vote on
     * @param support_ The support value for the vote. 0=against, 1=for, 2=abstain
     * @dev Reentrancy is defended against in `castVoteInternal` at the `receipt.hasVoted == false` require statement.
     */
    function castRefundableVote(uint256 proposalId, uint8 support) external refundable {
        require(votingRefund, "FrankenDAO::castRefundableVote: refunding gas is turned off");
        emit VoteCast(
            msg.sender, proposalId, support, castVoteInternal(msg.sender, proposalId, support)
        );
    }
    /**
     * @notice Internal function that caries out voting logic
     * @param voter The voter that is casting their vote
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain
     * @return The number of votes cast
     */
    function castVoteInternal(address voter, uint256 proposalId, uint8 support) internal returns (uint96) {
        // we can do this with no check because if you can vote, it means you have votes so you haven't delegated
        totalCommunityScoreData.votes += 1;
        uint256 userVoteCount = ++userCommunityScoreData[voter].votes;

        require(state(proposalId) == ProposalState.Active, "FrankenDAO::castVoteInternal: voting is closed");
        require(support <= 2, "FrankenDAO::castVoteInternal: invalid vote type");
        
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, "FrankenDAO::castVoteInternal: voter already voted");

        uint96 votes = staking.getVotes(voter);

        if (support == 0) {
            proposal.againstVotes = proposal.againstVotes + votes;
        } else if (support == 1) {
            proposal.forVotes = proposal.forVotes + votes;
        } else if (support == 2) {
            proposal.abstainVotes = proposal.abstainVotes + votes;
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        return votes;
    }


    /////////////////
    //// Helpers ////
    /////////////////
    function _removeFromActiveProposals(uint256 _id) private {
        uint256 index;
        uint[] actives = activeProposals;

        for (uint256 i = 0; i < actives.length; i++) {
            if(actives[i] == _id) {
                index = i;
                break;
            }
        }

        activeProposals[index] = activeProposals[activeProposals.length - 1];
        activeProposals.pop();
    }
    
    function updateTotalCommunityScoreData(uint64 _votes, uint64 _proposalsCreated, uint64 _proposalsPassed) external {
        require(msg.sender == staking, "FrankenDAO::updateTotalCommunityScoreData: only staking");

        totalCommunityScoreData.proposalsCreated = _proposalsCreated;
        totalCommunityScoreData.proposalsPassed = _proposalsPassed;
        totalCommunityScoreData.votes = _votes;

        emit TotalCommunityScoreDataUpdated(_proposalsCreated, _proposalsPassed, _votes);
    }

    ///////////////
    //// Admin ////
    ///////////////
    /**
     * @notice Admin function for setting turning gas refunds
     * on voting on and off
     */
    function setProposalRefund(bool _proposing) external onlyAdmin {
        emit VotingRefundSet(proposalRefund = _proposing);
    }

    /**
     * @notice Admin function for setting turning gas refunds
     * on voting on and off
     */
    function setVotingRefund(bool _voting) external onlyAdmin {
        emit ProposalRefundSet(votingRefund = _voting);
    }

    /**
     * @notice Admin function for setting the voting delay
     * @param newVotingDelay new voting delay, in blocks
     */
    function _setVotingDelay(uint256 newVotingDelay) external onlyAdmin {
        require(
            newVotingDelay >= MIN_VOTING_DELAY && newVotingDelay <= MAX_VOTING_DELAY,
            "FrankenDAO::_setVotingDelay: invalid voting delay"
        );
        uint256 oldVotingDelay = votingDelay;
        votingDelay = newVotingDelay;

        emit VotingDelaySet(oldVotingDelay, votingDelay);
    }

    /**
     * @notice Admin function for setting the voting period
     * @param newVotingPeriod new voting period, in blocks
     */
    function _setVotingPeriod(uint256 newVotingPeriod) external onlyAdmin {
        require(
            newVotingPeriod >= MIN_VOTING_PERIOD && newVotingPeriod <= MAX_VOTING_PERIOD,
            "FrankenDAO::_setVotingPeriod: invalid voting period"
        );
        uint256 oldVotingPeriod = votingPeriod;
        votingPeriod = newVotingPeriod;

        emit VotingPeriodSet(oldVotingPeriod, votingPeriod);
    }

    /**
     * @notice Admin function for setting the proposal threshold basis points
     * @dev newProposalThresholdBPS must be greater than the hardcoded min
     * @param newProposalThresholdBPS new proposal threshold
     */
    function _setProposalThresholdBPS(uint256 newProposalThresholdBPS)
        external onlyAdmin
    {
        require(
            newProposalThresholdBPS >= MIN_PROPOSAL_THRESHOLD_BPS &&
            newProposalThresholdBPS <= MAX_PROPOSAL_THRESHOLD_BPS,
            "FrankenDAO::_setProposalThreshold: invalid proposal threshold"
        );
        uint256 oldProposalThresholdBPS = proposalThresholdBPS;
        proposalThresholdBPS = newProposalThresholdBPS;

        emit ProposalThresholdBPSSet(oldProposalThresholdBPS, proposalThresholdBPS);
    }

    /**
     * @notice Admin function for setting the quorum votes basis points
     * @dev newQuorumVotesBPS must be greater than the hardcoded min
     * @param newQuorumVotesBPS new proposal threshold
     */
    function _setQuorumVotesBPS(uint256 newQuorumVotesBPS) external onlyAdmin {
        require(
            newQuorumVotesBPS >= MIN_QUORUM_VOTES_BPS &&
            newQuorumVotesBPS <= MAX_QUORUM_VOTES_BPS,
            "FrankenDAO::_setProposalThreshold: invalid proposal threshold"
        );
        uint256 oldQuorumVotesBPS = quorumVotesBPS;
        quorumVotesBPS = newQuorumVotesBPS;

        emit QuorumVotesBPSSet(oldQuorumVotesBPS, quorumVotesBPS);
    }
}
