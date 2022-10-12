// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./interfaces/IGovernance.sol";
import "./events/GovernanceEvents.sol";
import "./storage/GovernanceStorage.sol";
import "./Staking.sol";
import "./Executor.sol";
import "./utils/Admin.sol";
import "./utils/Refund.sol";

contract Governance is Admin, GovernanceStorage, GovernanceEvents, Refund {
    bool public initialized;

    /**
     * @notice Used to initialize the contract during delegator contructor
     * @param timelock_ The address of the FrankenDAOExecutor
     * @param staking_ The address of the NOUN tokens
     * @param vetoers_ List of addresses allowed to unilaterally veto proposals
     * @param votingPeriod_ The initial voting period
     * @param votingDelay_ The initial voting delay
     * @param proposalThresholdBPS_ The initial proposal threshold in basis points
     * * @param quorumVotesBPS_ The initial quorum votes threshold in basis points
     */
    function initialize(
        address payable timelock_,
        address staking_,
        address founders_,
        address council_,
        address[] memory vetoers_,
        uint256 votingPeriod_,
        uint256 votingDelay_,
        uint256 proposalThresholdBPS_,
        uint256 quorumVotesBPS_
    ) public virtual {
        require(!initialized, "FrankenDAOExecutor::initialize:already initialized");
        require(
            address(timelock) == address(0),
            "FrankenDAO::initialize: can only initialize once"
        );
        require(
            timelock_ != address(0),
            "FrankenDAO::initialize: invalid timelock address"
        );
        require(
            staking_ != address(0),
            "FrankenDAO::initialize: invalid staking address"
        );
        require(
            votingPeriod_ >= MIN_VOTING_PERIOD &&
                votingPeriod_ <= MAX_VOTING_PERIOD,
            "FrankenDAO::initialize: invalid voting period"
        );
        require(
            votingDelay_ >= MIN_VOTING_DELAY &&
                votingDelay_ <= MAX_VOTING_DELAY,
            "FrankenDAO::initialize: invalid voting delay"
        );
        require(
            proposalThresholdBPS_ >= MIN_PROPOSAL_THRESHOLD_BPS &&
                proposalThresholdBPS_ <= MAX_PROPOSAL_THRESHOLD_BPS,
            "FrankenDAO::initialize: invalid proposal threshold"
        );
        require(
            quorumVotesBPS_ >= MIN_QUORUM_VOTES_BPS &&
                quorumVotesBPS_ <= MAX_QUORUM_VOTES_BPS,
            "FrankenDAO::initialize: invalid proposal threshold"
        );

        emit VotingPeriodSet(votingPeriod, votingPeriod_);
        emit VotingDelaySet(votingDelay, votingDelay_);
        emit ProposalThresholdBPSSet(
            proposalThresholdBPS,
            proposalThresholdBPS_
        );
        emit QuorumVotesBPSSet(quorumVotesBPS, quorumVotesBPS_);

        timelock = Executor(timelock_);
        staking = Staking(staking_);
        votingPeriod = votingPeriod_;
        votingDelay = votingDelay_;
        proposalThresholdBPS = proposalThresholdBPS_;
        quorumVotesBPS = quorumVotesBPS_;

        executor = timelock_;
        founders = founders_;
        council = council_;

        // TODO: move to constructor?
        _setupRole(VETOER, msg.sender);
        emit NewVetoer(msg.sender);

        for (uint256 index = 0; index < vetoers_.length; index++) {
            _addVetoer(vetoers_[index]);
        }

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
    function getActions(uint256 proposalId)
        external
        view
        returns (
            address[] memory targets,
            uint256[] memory values,
            string[] memory signatures,
            bytes[] memory calldatas
        )
    {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    /**
     * @notice Gets the receipt for a voter on a given proposal
     * @param proposalId the id of proposal
     * @param voter The address of the voter
     * @return The voting receipt
     */
    function getReceipt(uint256 proposalId, address voter)
        external
        view
        returns (Receipt memory)
    {
        return proposals[proposalId].receipts[voter];
    }

    /**
     * @notice Gets the state of a proposal
     * @param proposalId The id of the proposal
     * @return Proposal state
     */
    function state(uint256 proposalId) public view returns (ProposalState) {
        require(
            proposalCount >= proposalId,
            "FrankenDAO::state: invalid proposal id"
        );
        Proposal storage proposal = proposals[proposalId];
        if (proposal.vetoed) {
            return ProposalState.Vetoed;
        } else if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (
            proposal.forVotes <= proposal.againstVotes ||
            proposal.forVotes < proposal.quorumVotes
        ) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= proposal.eta + timelock.GRACE_PERIOD()) {
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
        return bps2Uint(proposalThresholdBPS, staking.totalVotingPower());
    }

    /**
     * @notice Current quorum votes using Noun Total Supply
     * Differs from `GovernerBravo` which uses fixed amount
     */
    function quorumVotes() public view returns (uint256) {
        return bps2Uint(quorumVotesBPS, staking.totalVotingPower());
    }

    function bps2Uint(uint256 bps, uint256 number)
        internal
        pure
        returns (uint256)
    {
        return (number * bps) / 10000;
    }

    function getChainIdInternal() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    ///////////////////
    //// Proposals ////
    ///////////////////

    struct ProposalTemp {
        uint256 totalSupply;
        uint256 proposalThreshold;
        uint256 latestProposalId;
        uint256 startBlock;
        uint256 endBlock;
    }

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
        uint256 proposalId = _propose(
            targets,
            values,
            signatures,
            calldatas,
            description
        );

        return proposalId;
    }

    function proposeWithRefund(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) public refundable returns (uint256) {
        require(
            proposalRefund,
            "FrankenDAO::proposeWithRefund: refunding gas is turned off"
        );

        uint256 proposalId = _propose(
            targets,
            values,
            signatures,
            calldatas,
            description
        );

        return proposalId;
    }

    function _propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) internal returns (uint256) {
        uint256 userProposalCount = ++getCommunityScoreData[msg.sender].proposalsCreated;
        // we can do this with no check because if you can propose, it means you have votes so you haven't delegated
        totalCommunityVotingPowerBreakdown.proposalsCreated += 1;

        ProposalTemp memory temp;

        temp.totalSupply = staking.totalVotingPower();

        temp.proposalThreshold = bps2Uint(
            proposalThresholdBPS,
            temp.totalSupply
        );

        require(
            staking.getPriorVotes(msg.sender, block.number - 1) >
                temp.proposalThreshold,
            "FrankenDAO::propose: proposer votes below proposal threshold"
        );
        require(
            targets.length == values.length &&
                targets.length == signatures.length &&
                targets.length == calldatas.length,
            "FrankenDAO::propose: proposal function information arity mismatch"
        );
        require(
            targets.length != 0,
            "FrankenDAO::propose: must provide actions"
        );
        require(
            targets.length <= proposalMaxOperations,
            "FrankenDAO::propose: too many actions"
        );

        temp.latestProposalId = latestProposalIds[msg.sender];
        if (temp.latestProposalId != 0) {
            ProposalState proposersLatestProposalState = state(
                temp.latestProposalId
            );
            require(
                proposersLatestProposalState != ProposalState.Active,
                "FrankenDAO::propose: one live proposal per proposer, found an already active proposal"
            );
            require(
                proposersLatestProposalState != ProposalState.Pending,
                "FrankenDAO::propose: one live proposal per proposer, found an already pending proposal"
            );
        }

        temp.startBlock = block.number + votingDelay;
        temp.endBlock = temp.startBlock + votingPeriod;

        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];

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
        newProposal.verified = true;
        newProposal.canceled = false;
        newProposal.executed = false;
        newProposal.vetoed = false;

        latestProposalIds[newProposal.proposer] = newProposal.id;

        /// @notice Maintains backwards compatibility with GovernorBravo events
        emit ProposalCreated(
            newProposal.id,
            msg.sender,
            targets,
            values,
            signatures,
            calldatas,
            newProposal.startBlock,
            newProposal.endBlock,
            description
        );

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
    function verifyProposal(uint _id) external onlyVetoers {
        // Can't verify a proposal that's been vetoed, canceled,
        ProposalState state = state(_id);
        require(
            state == ProposalState.Pending || state == ProposalState.Active,
            "FrankenDAOGovernance::verifyProposal: proposal can't be verified"
        );

        proposals[_id].verified = true;

        // Add ID to activeProposals list
        activeProposals.push(_id);
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
        uint256 eta = block.timestamp + timelock.delay();
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            queueOrRevertInternal(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                eta
            );
        }
        proposal.eta = eta;

        // @todo Remove from activeProposals list
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
        require(
            !timelock.queuedTransactions(
                keccak256(abi.encode(target, value, signature, data, eta))
            ),
            "FrankenDAO::queueOrRevertInternal: identical proposal action already queued at eta"
        );
        timelock.queueTransaction(target, value, signature, data, eta);
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

        uint256 userSuccessfulProposalCount = ++getCommunityScoreData[proposal.proposer].proposalsPassed;
        // we can do this with no check because if you can propose, it means you have votes so you haven't delegated
        totalCommunityVotingPowerBreakdown.proposalsPassed += 1;
        
        proposal.executed = true;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            timelock.executeTransaction(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
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
        require(
            state(proposalId) != ProposalState.Executed,
            "FrankenDAO::cancel: cannot cancel executed proposal"
        );

        Proposal storage proposal = proposals[proposalId];
        require(
            msg.sender == proposal.proposer ||
                staking.getPriorVotes(proposal.proposer, block.number - 1) <
                proposal.proposalThreshold,
            "FrankenDAO::cancel: proposer above threshold"
        );

        proposal.canceled = true;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            timelock.cancelTransaction(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }

        // @todo Remove from activeProposals list
        _removeFromActiveProposals(proposalId);

        emit ProposalCanceled(proposalId);
    }

    /**
     * @notice Vetoes a proposal only if sender has the VETOER role and the proposal has not been executed.
     * @param proposalId The id of the proposal to veto
     */
    // @todo - only things to add here is the vetoer logic
    // - Veto ability which allows `veteor` to halt any proposal at any stage unless the proposal is executed.
    //   The `veto(uint proposalId)` logic is a modified version of `cancel(uint proposalId)`
    //   A `vetoed` flag was added to the `Proposal` struct to support this.
    // we'll probably just copy and edit the Compound contracts directly rather than import and edit
    function veto(uint256 proposalId) external {
        require(canVeto(), "FrankenDAO::veto: only vetoer");
        require(
            state(proposalId) != ProposalState.Executed,
            "FrankenDAO::veto: cannot veto executed proposal"
        );

        Proposal storage proposal = proposals[proposalId];

        proposal.vetoed = true;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            timelock.cancelTransaction(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }

        // @todo Remove from activeProposals list
        _removeFromActiveProposals(proposalId);

        emit ProposalVetoed(proposalId);
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
            msg.sender,
            proposalId,
            support,
            castVoteInternal(msg.sender, proposalId, support)
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
    function castRefundableVote(uint256 proposalId_, uint8 support_) external
    refundable {
        // @todo why doesn't refundable vote emit event?
        require(
            votingRefund,
            "FrankenDAO::castRefundableVote: refunding gas is turned off"
        );
        uint96 votes = castVoteInternal(msg.sender, proposalId_, support_);
        emit VoteCast(msg.sender, proposalId_, support_, votes);
    }
    /**
     * @notice Internal function that caries out voting logic
     * @param voter The voter that is casting their vote
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain
     * @return The number of votes cast
     */
    function castVoteInternal(
        address voter,
        uint256 proposalId,
        uint8 support
    ) internal returns (uint96) {
        uint256 userVoteCount = ++getCommunityScoreData[voter].votes;
        // we can do this with no check because if you can propose, it means you have votes so you haven't delegated
        totalCommunityVotingPowerBreakdown.votes += 1;

        require(
            state(proposalId) == ProposalState.Active,
            "FrankenDAO::castVoteInternal: voting is closed"
        );
        require(
            support <= 2,
            "FrankenDAO::castVoteInternal: invalid vote type"
        );
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(
            receipt.hasVoted == false,
            "FrankenDAO::castVoteInternal: voter already voted"
        );

        /// @notice: Unlike GovernerBravo, votes are considered from the block the proposal was created in order to normalize quorumVotes and proposalThreshold metrics
        uint96 votes = staking.getPriorVotes(
            voter,
            proposal.startBlock - votingDelay
        );

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

    ///////////////
    //// Admin ////
    ///////////////
    /**
     * @notice Admin function for setting turning gas refunds
     * on voting on and off
     */
    function setProposalRefund(bool _proposing) external {
        require(
            isAdmin(),
            "FrankenDAO::setProposalRefund: admin only"
        );

        proposalRefund = _proposing;

        emit VotingRefundSet(_proposing);
    }

    /**
     * @notice Admin function for setting turning gas refunds
     * on voting on and off
     */
    function setVotingRefund(bool _voting) external {
        require(
        isAdmin(),
            "FrankenDAO::setVotingRefund: admin only"
        );

        votingRefund = _voting;

        emit ProposalRefundSet(_voting);
    }

    /**
     * @notice Admin function for setting the voting delay
     * @param newVotingDelay new voting delay, in blocks
     */
    function _setVotingDelay(uint256 newVotingDelay) external {
        require(isAdmin(), "FrankenDAO::_setVotingDelay: admin only");
        require(
            newVotingDelay >= MIN_VOTING_DELAY &&
                newVotingDelay <= MAX_VOTING_DELAY,
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
    function _setVotingPeriod(uint256 newVotingPeriod) external {
        require(
            isAdmin(),
            "FrankenDAO::_setVotingPeriod: admin only"
        );
        require(
            newVotingPeriod >= MIN_VOTING_PERIOD &&
                newVotingPeriod <= MAX_VOTING_PERIOD,
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
        external
    {
        require(
            isAdmin(),
            "FrankenDAO::_setProposalThresholdBPS: admin only"
        );
        require(
            newProposalThresholdBPS >= MIN_PROPOSAL_THRESHOLD_BPS &&
                newProposalThresholdBPS <= MAX_PROPOSAL_THRESHOLD_BPS,
            "FrankenDAO::_setProposalThreshold: invalid proposal threshold"
        );
        uint256 oldProposalThresholdBPS = proposalThresholdBPS;
        proposalThresholdBPS = newProposalThresholdBPS;

        emit ProposalThresholdBPSSet(
            oldProposalThresholdBPS,
            proposalThresholdBPS
        );
    }

    /**
     * @notice Admin function for setting the quorum votes basis points
     * @dev newQuorumVotesBPS must be greater than the hardcoded min
     * @param newQuorumVotesBPS new proposal threshold
     */
    function _setQuorumVotesBPS(uint256 newQuorumVotesBPS) external {
        require(
            isAdmin(),
            "FrankenDAO::_setQuorumVotesBPS: admin only"
        );
        require(
            newQuorumVotesBPS >= MIN_QUORUM_VOTES_BPS &&
                newQuorumVotesBPS <= MAX_QUORUM_VOTES_BPS,
            "FrankenDAO::_setProposalThreshold: invalid proposal threshold"
        );
        uint256 oldQuorumVotesBPS = quorumVotesBPS;
        quorumVotesBPS = newQuorumVotesBPS;

        emit QuorumVotesBPSSet(oldQuorumVotesBPS, quorumVotesBPS);
    }

    function _removeFromActiveProposals(uint256 _id) private {
        uint256 index;

        for (uint256 i = 0; i < array.length; i++) {
            if(activeProposals[i] == _id) {
                index = i;
                break;
            }
        }

        delete activeProposals[index];
        activeProposals[index] = activeProposals[activeProposals.length - 1];
        activeProposals.pop();
    }
    
    function updateTotalCommunityVotingPowerBreakdown(
        uint64 _votes,
        uint64 _proposalsCreated,
        uint64 _proposalsPassed
    ) external {
        require(
            msg.sender == staking,
            "FrankenDAO::updateTotalCommunityVotingPowerBreakdown: only staking"
        );

        totalCommunityVotingPowerBreakdown.proposalsCreated = _proposalsCreated;
        totalCommunityVotingPowerBreakdown.proposalsPassed = _proposalsPassed;
        totalCommunityVotingPowerBreakdown.votes = _votes;

        emit TotalCommunityVotingPowerBreakdownUpdated(
            _proposalsCreated,
            _proposalsPassed,
            _votes
        );
    }
}
