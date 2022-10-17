// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./interfaces/IGovernance.sol";
import "./Staking.sol";
import "./interfaces/IExecutor.sol";
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

    RefundStatus public refund;

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
     * @param _executor The address of the FrankenDAOExecutor
     * @param _staking The address of the staked FrankenPunks tokens
     * @param _founders The address of the founder's multi-sig
     * @param _council The address of the council's multi-sig
     * @param _votingPeriod The initial voting period
     * @param _votingDelay The initial voting delay
     * @param _proposalThresholdBPS The initial proposal threshold in basis points
     * @param _quorumVotesBPS The initial quorum votes threshold in basis points
     */
    function initialize(
        address _staking,
        address payable _executor,
        address _founders,
        address _council,
        uint256 _votingPeriod,
        uint256 _votingDelay,
        uint256 _proposalThresholdBPS,
        uint256 _quorumVotesBPS
    ) public virtual {
        if (initialized) revert AlreadyInitialized();
        if(_staking == address(0)) revert ZeroAddress();
        if (_votingPeriod < MIN_VOTING_PERIOD || _votingPeriod > MAX_VOTING_PERIOD) revert ParameterOutOfBounds();
        if (_votingDelay < MIN_VOTING_DELAY || _votingDelay > MAX_VOTING_DELAY) revert ParameterOutOfBounds();
        if (_proposalThresholdBPS < MIN_PROPOSAL_THRESHOLD_BPS || _proposalThresholdBPS > MAX_PROPOSAL_THRESHOLD_BPS) revert ParameterOutOfBounds();
        if (_quorumVotesBPS < MIN_QUORUM_VOTES_BPS || _quorumVotesBPS > MAX_QUORUM_VOTES_BPS) revert ParameterOutOfBounds();

        executor = IExecutor(_executor);
        founders = _founders;
        council = _council;

        staking = Staking(_staking);
        votingPeriod = _votingPeriod;
        votingDelay = _votingDelay;
        proposalThresholdBPS = _proposalThresholdBPS;
        quorumVotesBPS = _quorumVotesBPS;

        initialized = true;

        emit VotingPeriodSet(votingPeriod, _votingPeriod);
        emit VotingDelaySet(votingDelay, _votingDelay);
        emit ProposalThresholdBPSSet( proposalThresholdBPS, _proposalThresholdBPS );
        emit QuorumVotesBPSSet(quorumVotesBPS, _quorumVotesBPS);
    }

    ///////////////
    //// Views ////
    ///////////////
    /**
     * @notice Gets actions of a proposal
     * @param _proposalId the id of the proposal
     * @return targets
     * @return values
     * @return signatures
     * @return calldatas
     */
    function getActions(uint256 _proposalId) external view returns (
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas
    ) {
        Proposal storage p = proposals[_proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    function getProposalData(uint256 _id) public view returns (uint256, address, uint256, uint256) {
        Proposal storage p = proposals[_id];
        return (p.id, p.proposer, p.proposalThreshold, p.quorumVotes);
    }

    /// @notice get the status of a proposal
    function getProposalStatus(uint256 _id) public view returns (bool, bool, bool) {
        Proposal storage p = proposals[_id];
        return (p.canceled, p.vetoed, p.executed);
    }

    function getProposalVotes(uint256 _id) public view returns (uint256, uint256, uint256) {
        Proposal storage p = proposals[_id];
        return (p.forVotes, p.againstVotes, p.abstainVotes);
    }

    function getActiveProposals() public view returns (uint256[] memory) {
        return activeProposals;
    }

    /**
     * @notice Gets the receipt for a voter on a given proposal
     * @param _proposalId the id of proposal
     * @param _voter The address of the voter
     * @return The voting receipt
     */
    function getReceipt(uint256 _proposalId, address _voter) external view returns (Receipt memory) {
        return proposals[_proposalId].receipts[_voter];
    }

    /**
     * @notice Gets the state of a proposal
     * @param _proposalId The id of the proposal
     * @return Proposal state
     */
    function state(uint256 _proposalId) public view returns (ProposalState) {
        if(_proposalId > proposalCount) revert InvalidId();
        Proposal storage proposal = proposals[_proposalId];
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

    function bps2Uint(uint256 _bps, uint256 _number) internal pure returns (uint256) {
        return (_number * _bps) / 10000;
    }

    ///////////////////
    //// Proposals ////
    ///////////////////

    /**
     * @notice Function used to propose a new proposal. Sender must have delegates above the proposal threshold
     * @param _targets Target addresses for proposal calls
     * @param _values Eth values for proposal calls
     * @param _signatures Function signatures for proposal calls
     * @param _calldatas Calldatas for proposal calls
     * @param _description String description of the proposal
     * @return Proposal id of new proposal
     */
    function propose(
        address[] memory _targets,
        uint256[] memory _values,
        string[] memory _signatures,
        bytes[] memory _calldatas,
        string memory _description
    ) public returns (uint256) {
        uint256 proposalId = _propose(_targets, _values, _signatures,
                                      _calldatas, _description);
        return proposalId;
    }

    function proposeWithRefund(
        address[] memory _targets,
        uint256[] memory _values,
        string[] memory _signatures,
        bytes[] memory _calldatas,
        string memory _description
    ) public refundable returns (uint256) {
        if(refund != RefundStatus.ProposalRefund && refund != RefundStatus.VotingAndProposalRefund) revert NotRefundable();
        uint256 proposalId = _propose(
            _targets,
            _values,
            _signatures,
            _calldatas,
            _description
        );
        return proposalId;
    }

    function _propose(
        address[] memory _targets,
        uint256[] memory _values,
        string[] memory _signatures,
        bytes[] memory _calldatas,
        string memory _description
    ) internal returns (uint256) {
        ProposalTemp memory temp;

        temp.totalSupply = staking.getTotalVotingPower();
        temp.proposalThreshold = bps2Uint(proposalThresholdBPS, temp.totalSupply);
        if(staking.getVotes(msg.sender) < tmp.proposalThreshold) revert NotEligible();

        if (_targets.length == 0) revert InvalidProposal();
        if(_targets.length > PROPOSAL_MAX_OPERATIONS) revert InvalidProposal();
        if(
            _targets.length != _values.length ||
            _targets.length != _signatures.length ||
            _targets.length != _calldatas.length
        ) revert InvalidProposal();

        temp.latestProposalId = latestProposalIds[msg.sender];
        if (temp.latestProposalId != 0) {
            ProposalState proposersLatestProposalState = state(temp.latestProposalId);
            if ( proposersLatestProposalState == ProposalState.Active || proposersLatestProposalState == ProposalState.Pending ) revert NotEligible();
        }

        temp.startBlock = block.number + votingDelay;
        temp.endBlock = temp.startBlock + votingPeriod;

        Proposal storage newProposal = proposals[++proposalCount];

        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.proposalThreshold = temp.proposalThreshold;
        newProposal.quorumVotes = bps2Uint(quorumVotesBPS, temp.totalSupply);
        newProposal.eta = 0;
        newProposal.targets = _targets;
        newProposal.values = _values;
        newProposal.signatures = _signatures;
        newProposal.calldatas = _calldatas;
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
        activeProposals.push(newProposal.id);

        /// @notice Updated event with `proposalThreshold` and `quorumVotes`
        emit ProposalCreatedWithRequirements(
            newProposal.id,
            msg.sender,
            _targets,
            _values,
            _signatures,
            _calldatas,
            newProposal.startBlock,
            newProposal.endBlock,
            newProposal.proposalThreshold,
            newProposal.quorumVotes,
            _description
        );

        return newProposal.id;
    }

    /// @notice Function for verifying a proposal
    /// @param _proposalId Id of the proposal to verify
    function verifyProposal(uint _proposalId) external onlyVetoers {
        // Can't verify a proposal that's been vetoed, canceled,
        if(state(_proposalId) != ProposalState.Pending) revert InvalidStatus();

        Proposal storage proposal = proposals[_proposalId];

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
     * @param _proposalId The id of the proposal to queue
     */
    function queue(uint256 _proposalId) external {
        if(state(_proposalId) != ProposalState.Succeeded) revert InvalidStatus();
        Proposal storage proposal = proposals[_proposalId];
        uint256 eta = block.timestamp + executor.delay();
        uint numTargets = proposal.targets.length;
        for (uint256 i = 0; i < numTargets; i++) {
            queueOrRevertInternal(
                proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta
            );
        }
        proposal.eta = eta;

        _removeFromActiveProposals(_proposalId);

        emit ProposalQueued(_proposalId, eta);
    }

    function queueOrRevertInternal(
        address _target,
        uint256 _value,
        string memory _signature,
        bytes memory _data,
        uint256 _eta
    ) internal {
        if(executor.queuedTransactions(keccak256(abi.encode(_target, _value, _signature, _data, _eta)))) revert AlreadyQueued();
        executor.queueTransaction(_target, _value, _signature, _data, _eta);
    }

    /**
     * @notice Executes a queued proposal if eta has passed
     * @param _proposalId The id of the proposal to execute
     */
    function execute(uint256 _proposalId) external {
        if(state(_proposalId) != ProposalState.Queued) revert InvalidStatus();
        Proposal storage proposal = proposals[_proposalId];

        uint256 userSuccessfulProposalCount = ++userCommunityScoreData[proposal.proposer].proposalsPassed;
        // we can do this with no check because if you can propose, it means you have votes so you haven't delegated
        totalCommunityScoreData.proposalsPassed += 1;
        
        proposal.executed = true;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            executor.executeTransaction(
                proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta
            );
        }
        emit ProposalExecuted(_proposalId);
    }

    ////////////////////////////////
    //// Cancel / Veto Proposal ////
    ////////////////////////////////
    /**
     * @notice Cancels a proposal only if sender is the proposer, or proposer delegates dropped below proposal threshold
     * @param _proposalId The id of the proposal to cancel
     */
    function cancel(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.executed || proposal.canceled || proposal.vetoed) revert InvalidStatus();
        if(
            msg.sender != proposal.proposer &&
            staking.getVotes(proposal.proposer) < proposal.proposalThreshold && 
            !proposal.verified &&
            block.number < proposal.endBlock &&
            state(_proposalId) == ProposalState.Expired
        ) revert NotEligible();

        _removeTransactionIfQueuedOrExpired(proposal);

        proposal.canceled = true;        

        emit ProposalCanceled(_proposalId);
    }

    /**
     * @notice Vetoes a proposal only if sender has ability to veto a proposal
     * @param _proposalId The id of the proposal to veto
     */
    function veto(uint256 _proposalId) external onlyAdmins {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.executed || proposal.canceled || proposal.vetoed) revert InvalidStatus();

        _removeTransactionIfQueuedOrExpired(proposal);

        proposal.vetoed = true;

        emit ProposalVetoed(_proposalId);
    }

    function _removeTransactionIfQueuedOrExpired(Proposal storage _proposal) internal {
        if (
            state(_proposal.id) == ProposalState.Queued || 
            state(_proposal.id) == ProposalState.Expired
        ) {
            for (uint256 i = 0; i < _proposal.targets.length; i++) {
                executor.cancelTransaction(
                    _proposal.targets[i],
                    _proposal.values[i],
                    _proposal.signatures[i],
                    _proposal.calldatas[i],
                    _proposal.eta
                );
            }
        } else {
            _removeFromActiveProposals(_proposal.id);
        }
    }

    ////////////////
    //// Voting ////
    ////////////////
    /**
     * @notice Cast a vote for a proposal
     * @param _proposalId The id of the proposal to vote on
     * @param _support The support value for the vote. 0=against, 1=for, 2=abstain
     */
    function castVote(uint256 _proposalId, uint8 _support) external {
        emit VoteCast( 
            msg.sender, _proposalId, _support, castVoteInternal(msg.sender,
                                                                _proposalId, _support) 
        );
    }

    /**
     * @notice Cast a vote for a proposal, asking the DAO to refund gas costs.
     * Users with > 0 votes receive refunds. Refunds are partial when using a gas priority fee higher than the DAO's cap.
     * Refunds are partial when the DAO's balance is insufficient.
     * No refund is sent when the DAO's balance is empty. No refund is sent to users with no votes.
     * Voting takes place regardless of refund success.
     * @param _proposalId The id of the proposal to vote on
     * @param _support The support value for the vote. 0=against, 1=for, 2=abstain
     * @dev Reentrancy is defended against in `castVoteInternal` at the `receipt.hasVoted == false` require statement.
     */
    function castRefundableVote(uint256 _proposalId, uint8 _support)
        external
        refundable
    {
        if (refund != RefundStatus.VotingRefund && refund != RefundStatus.VotingAndProposalRefund) revert NotRefundable();
        emit VoteCast(
            msg.sender,
            _proposalId,
            _support,
            castVoteInternal(msg.sender, _proposalId, _support)
        );
    }

    /**
     * @notice Internal function that caries out voting logic
     * @param _voter The voter that is casting their vote
     * @param _proposalId The id of the proposal to vote on
     * @param _support The support value for the vote. 0=against, 1=for, 2=abstain
     * @return The number of votes cast
     */
    function castVoteInternal(address _voter, uint256 _proposalId, uint8 _support) internal returns (uint) {
        // we can do this with no check because if you can vote, it means you have votes so you haven't delegated
        totalCommunityScoreData.votes += 1;
        uint256 userVoteCount = ++userCommunityScoreData[_voter].votes;

        if (state(_proposalId) != ProposalState.Active) revert InvalidStatus();
        if (_support > 2) revert InvalidInput();
        
        Proposal storage proposal = proposals[_proposalId];
        Receipt storage receipt = proposal.receipts[_voter];
        if (receipt.hasVoted) revert AlreadyVoted();

        uint votes = staking.getVotes(_voter);

        if (_support == 0) {
            proposal.againstVotes = proposal.againstVotes + votes;
        } else if (_support == 1) {
            proposal.forVotes = proposal.forVotes + votes;
        } else if (_support == 2) {
            proposal.abstainVotes = proposal.abstainVotes + votes;
        }

        receipt.hasVoted = true;
        receipt.support = _support;
        // Can't overflow because there will never be more than 2 ** 96 votes in the system.
        receipt.votes = uint96(votes);

        return votes;
    }


    /////////////////
    //// Helpers ////
    /////////////////
    function _removeFromActiveProposals(uint256 _id) private {
        uint256 index;
        uint[] memory actives = activeProposals;

        for (uint256 i = 0; i < actives.length; i++) {
            if(actives[i] == _id) {
                index = i;
                break;
            }
        }

        activeProposals[index] = activeProposals[actives.length - 1];
        activeProposals.pop();
    }
    
    function updateTotalCommunityScoreData(uint64 _votes, uint64 _proposalsCreated, uint64 _proposalsPassed) external {
        if (msg.sender != address(staking)) revert NotAuthorized();

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
     * on voting on and official
     * @param _refundStatus RefundStatus value
     */
    function setRefund(RefundStatus _refundStatus) external onlyExecutor {
        emit RefundSet(refund = _refundStatus);
    }

    /**
     * @notice Admin function for setting the voting delay
     * @param _newVotingDelay new voting delay, in blocks
     */
    function _setVotingDelay(uint256 _newVotingDelay) external onlyExecutor {
        if (_newVotingDelay < MIN_VOTING_DELAY || _newVotingDelay > MAX_VOTING_DELAY) revert ParameterOutOfBounds();
        uint256 oldVotingDelay = votingDelay;
        votingDelay = _newVotingDelay;

        emit VotingDelaySet(oldVotingDelay, votingDelay);
    }

    /**
     * @notice Admin function for setting the voting period
     * @param _newVotingPeriod new voting period, in blocks
     */
    function _setVotingPeriod(uint256 _newVotingPeriod) external onlyExecutor {
        if (_newVotingPeriod < MIN_VOTING_PERIOD || _newVotingPeriod > MAX_VOTING_DELAY) revert ParameterOutOfBounds();
        uint256 oldVotingPeriod = votingPeriod;
        votingPeriod = _newVotingPeriod;

        emit VotingPeriodSet(oldVotingPeriod, votingPeriod);
    }

    /**
     * @notice Admin function for setting the proposal threshold basis points
     * @dev _newProposalThresholdBPS must be greater than the hardcoded min
     * @param _newProposalThresholdBPS new proposal threshold
     */
    function _setProposalThresholdBPS(uint256 _newProposalThresholdBPS) external onlyExecutorOrAdmins {
        if (_newProposalThresholdBPS < MIN_PROPOSAL_THRESHOLD_BPS || _newProposalThresholdBPS > MAX_PROPOSAL_THRESHOLD_BPS) revert ParameterOutOfBounds();
        uint256 oldProposalThresholdBPS = proposalThresholdBPS;
        proposalThresholdBPS = _newProposalThresholdBPS;

        emit ProposalThresholdBPSSet(oldProposalThresholdBPS, proposalThresholdBPS);
    }

    /**
     * @notice Admin function for setting the quorum votes basis points
     * @dev _newQuorumVotesBPS must be greater than the hardcoded min
     * @param _newQuorumVotesBPS new proposal threshold
     */
    function _setQuorumVotesBPS(uint256 _newQuorumVotesBPS) external onlyExecutorOrAdmins {
        if (_newQuorumVotesBPS < MIN_QUORUM_VOTES_BPS || _newQuorumVotesBPS > MAX_QUORUM_VOTES_BPS) revert ParameterOutOfBounds();
        uint256 oldQuorumVotesBPS = quorumVotesBPS;
        quorumVotesBPS = _newQuorumVotesBPS;

        emit QuorumVotesBPSSet(oldQuorumVotesBPS, quorumVotesBPS);
    }
}
