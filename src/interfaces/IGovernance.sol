pragma solidity ^0.8.10;

import {IStaking} from "./IStaking.sol";

interface IGovernance {

    ////////////////////
    ////// Events //////
    ////////////////////

    /// @notice Emited when a proposal is canceled
    event ProposalCanceled(uint256 id);
    /// @notice Emited when a proposal is created
    event ProposalCreated( uint256 id, address proposer, address[] targets, uint256[] values, string[] signatures, bytes[] calldatas, uint256 startTime, uint256 endTime, uint256 proposalThreshold, uint256 quorumVotes, string description);
    /// @notice Emited when a proposal is executed
    event ProposalExecuted(uint256 id);
    /// @notice Emited when a proposal is queued
    event ProposalQueued(uint256 id, uint256 eta);
    /// @notice Emited when a new proposal threshold BPS is set
    event ProposalThresholdBPSSet(uint256 oldProposalThresholdBPS, uint256 newProposalThresholdBPS);
    /// @notice Emited when a proposal is vetoed
    event ProposalVetoed(uint256 id);
    /// @notice Emited when a new quorum votes BPS is set
    event QuorumVotesBPSSet(uint256 oldQuorumVotesBPS, uint256 newQuorumVotesBPS);
    /// @notice Emited when the refund status changes
    event RefundSet(uint8 status);
    /// @notice Emited when the total community score data is updated
    event TotalCommunityScoreDataUpdated(uint64 proposalsCreated, uint64 proposalsPassed, uint64 votes);
    /// @notice Emited when a vote is cast
    event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 votes);
    /// @notice Emited when the voting delay is updated
    event VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay);
    /// @notice Emited when the voting period is updated
    event VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod);

    ////////////////////
    ////// Errors //////
    ////////////////////

    /// @notice Error emited if an address is 0x000
    error ZeroAddress();
    /// @notice Error emited if someone calls the initializer a second time
    error AlreadyInitialized();
    /// @notice Error emited if a parameter value is out of range
    error ParameterOutOfBounds();
    /// @notice Error emited if a proposal doesn't exist for a given ID
    error InvalidId();
    /// @notice Error emited if the requirements for a proposal are not met
    error InvalidProposal();
    /// @notice Error emited if an unauthorized action is attempted, given
    //a proposal's current state
    error InvalidStatus();
    /// @notice Error emited if an invalid proposal is removed from the list of
    //active proposals
    error NotInActiveProposals();
    /// @notice Error emited if an invalid vote is attempted (not 0, 1, or 2)
    error InvalidInput();
    /// @notice Error emited if someone tries to vote a second time
    error AlreadyVoted();
    /// @notice Error emited if someone is not elegible to perform an action
    //(i.e. creating a proposal)
    error NotEligible();

    /////////////////////
    ////// Storage //////
    /////////////////////

    enum RefundStatus {
        VotingAndProposalRefund,
        VotingRefund,
        ProposalRefund,
        NoRefunds
    }

    struct ProposalTemp {
        uint256 totalSupply;
        uint256 proposalThreshold;
        uint256 latestProposalId;
        uint256 startTime;
        uint256 endTime;
    }

    struct CommunityScoreData {
        uint64 votes;
        uint64 proposalsCreated;
        uint64 proposalsPassed;
    }

    struct Proposal {
        /// @notice Unique id for looking up a proposal
        uint256 id;
        /// @notice Creator of the proposal
        address proposer;
        /// @notice The number of votes needed to create a proposal at the time of proposal creation. *DIFFERS from GovernerBravo
        uint256 proposalThreshold;
        /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed at the time of proposal creation. *DIFFERS from GovernerBravo
        uint256 quorumVotes;
        /// @notice The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint256 eta;
        /// @notice the ordered list of target addresses for calls to be made
        address[] targets;
        /// @notice The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        uint256[] values;
        /// @notice The ordered list of function signatures to be called
        string[] signatures;
        /// @notice The ordered list of calldata to be passed to each call
        bytes[] calldatas;
        /// @notice The block at which voting begins: holders must delegate their votes prior to this block
        uint256 startTime;
        /// @notice The block at which voting ends: votes must be cast prior to this block
        uint256 endTime;
        /// @notice Current number of votes in favor of this proposal
        uint256 forVotes;
        /// @notice Current number of votes in opposition to this proposal
        uint256 againstVotes;
        /// @notice Current number of votes for abstaining for this proposal
        uint256 abstainVotes;
        /// @notice Flag marking whether a proposal has been verified
        bool verified;
        /// @notice Flag marking whether the proposal has been canceled
        bool canceled;
        /// @notice Flag marking whether the proposal has been vetoed
        bool vetoed;
        /// @notice Flag marking whether the proposal has been executed
        bool executed;
        /// @notice Receipts of ballots for the entire set of voters
        mapping(address => Receipt) receipts;
    }

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        /// @notice Whether or not a vote has been cast
        bool hasVoted;
        /// @notice Whether or not the voter supports the proposal or abstains
        uint8 support;
        /// @notice The number of votes the voter had, which were cast
        uint96 votes;
    }

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

    /////////////////////
    ////// Methods //////
    /////////////////////

    function MAX_PROPOSAL_THRESHOLD_BPS() external view returns (uint256);
    function MAX_QUORUM_VOTES_BPS() external view returns (uint256);
    function MAX_VOTING_DELAY() external view returns (uint256);
    function MAX_VOTING_PERIOD() external view returns (uint256);
    function MIN_PROPOSAL_THRESHOLD_BPS() external view returns (uint256);
    function MIN_QUORUM_VOTES_BPS() external view returns (uint256);
    function MIN_VOTING_DELAY() external view returns (uint256);
    function MIN_VOTING_PERIOD() external view returns (uint256);
    function PROPOSAL_MAX_OPERATIONS() external view returns (uint256);
    function activeProposals(uint256) external view returns (uint256);
    function cancel(uint256 _proposalId) external;
    function castVote(uint256 _proposalId, uint8 _support) external;
    function clear(uint256 _proposalId) external;
    function execute(uint256 _proposalId) external;
    function getActions(uint256 _proposalId)
        external
        view
        returns (
            address[] memory targets,
            uint256[] memory values,
            string[] memory signatures,
            bytes[] memory calldatas
        );
    function getActiveProposals() external view returns (uint256[] memory);
    function getProposalData(uint256 _id) external view returns (uint256, address, uint256, uint256);
    function getProposalStatus(uint256 _id) external view returns (bool, bool, bool);
    function getProposalVotes(uint256 _id) external view returns (uint256, uint256, uint256);
    function getReceipt(uint256 _proposalId, address _voter) external view returns (Receipt memory);
    function initialize(
        address _staking,
        address _executor,
        address _founders,
        address _council,
        uint256 _votingPeriod,
        uint256 _votingDelay,
        uint256 _proposalThresholdBPS,
        uint256 _quorumVotesBPS
    ) external;
    function latestProposalIds(address) external view returns (uint256);
    function name() external view returns (string memory);
    function proposalCount() external view returns (uint256);
    function proposalRefund() external view returns (bool);
    function proposalThreshold() external view returns (uint256);
    function proposalThresholdBPS() external view returns (uint256);
    function proposals(uint256)
        external
        view
        returns (
            uint256 id,
            address proposer,
            uint256 proposalThreshold,
            uint256 quorumVotes,
            uint256 eta,
            uint256 startTime,
            uint256 endTime,
            uint256 forVotes,
            uint256 againstVotes,
            uint256 abstainVotes,
            bool verified,
            bool canceled,
            bool vetoed,
            bool executed
        );
    function propose(
        address[] memory _targets,
        uint256[] memory _values,
        string[] memory _signatures,
        bytes[] memory _calldatas,
        string memory _description
    ) external returns (uint256);
    function queue(uint256 _proposalId) external;
    function quorumVotes() external view returns (uint256);
    function quorumVotesBPS() external view returns (uint256);
    function setProposalThresholdBPS(uint256 _newProposalThresholdBPS) external;
    function setQuorumVotesBPS(uint256 _newQuorumVotesBPS) external;
    function setStakingAddress(IStaking _newStaking) external;
    function setVotingDelay(uint256 _newVotingDelay) external;
    function setVotingPeriod(uint256 _newVotingPeriod) external;
    function staking() external view returns (IStaking);
    function state(uint256 _proposalId) external view returns (ProposalState);
    function totalCommunityScoreData()
        external
        view
        returns (uint64 votes, uint64 proposalsCreated, uint64 proposalsPassed);
    function updateTotalCommunityScoreData(uint64 _votes, uint64 _proposalsCreated, uint64 _proposalsPassed) external;
    function userCommunityScoreData(address)
        external
        view
        returns (uint64 votes, uint64 proposalsCreated, uint64 proposalsPassed);
    function verifyProposal(uint256 _proposalId) external;
    function veto(uint256 _proposalId) external;
    function votingDelay() external view returns (uint256);
    function votingPeriod() external view returns (uint256);
    function votingRefund() external view returns (bool);
}
