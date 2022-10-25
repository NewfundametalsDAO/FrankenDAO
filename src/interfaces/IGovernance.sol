pragma solidity ^0.8.13;

interface IGovernance {
    event RefundSet(RefundStatus status);

    // Errors
    error ZeroAddress();
    error AlreadyInitialized();
    error ParameterOutOfBounds();
    error InvalidId();
    error InvalidProposal();
    error InvalidStatus();
    error InvalidInput();
    error AlreadyQueued();
    error AlreadyVoted();
    error RequirementsNotMet();
    error NotEligible();

    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(
        uint256 id,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startTime,
        uint256 endTime,
        string description
    );

    /// @notice An event emitted when a new proposal is created, which includes additional information
    event ProposalCreatedWithRequirements(
        uint256 id,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startTime,
        uint256 endTime,
        uint256 proposalThreshold,
        uint256 quorumVotes,
        string description
    );

    /// @notice An event emitted when a vote has been cast on a proposal
    /// @param voter The address which casted a vote
    /// @param proposalId The proposal id which was voted on
    /// @param support Support value for the vote. 0=against, 1=for, 2=abstain
    /// @param votes Number of votes which were cast by the voter
    event VoteCast(
        address indexed voter,
        uint256 proposalId,
        uint8 support,
        uint256 votes
    );

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint256 id);

    /// @notice An event emitted when a proposal has been queued in the FrankenDAOExecutor
    event ProposalQueued(uint256 id, uint256 eta);

    /// @notice An event emitted when a proposal has been executed in the FrankenDAOExecutor
    event ProposalExecuted(uint256 id);

    /// @notice An event emitted when a proposal has been vetoed by vetoAddress
    event ProposalVetoed(uint256 id);

    /// @notice An event emitted when the voting delay is set
    event VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay);

    /// @notice An event emitted when the voting period is set
    event VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod);

    /// @notice Emitted when implementation is changed
    event NewImplementation(
        address oldImplementation,
        address newImplementation
    );

    /// @notice Emitted when proposal threshold basis points is set
    event ProposalThresholdBPSSet(
        uint256 oldProposalThresholdBPS,
        uint256 newProposalThresholdBPS
    );

    /// @notice Emitted when quorum votes basis points is set
    event QuorumVotesBPSSet(
        uint256 oldQuorumVotesBPS,
        uint256 newQuorumVotesBPS
    );

    event TotalCommunityScoreDataUpdated(
        uint64 proposalsCreated,
        uint64 proposalsPassed,
        uint64 votes
    );

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

    // function BALLOT_TYPEHASH() external view returns (bytes32);
    // function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
    // function DOMAIN_TYPEHASH() external view returns (bytes32);
    // function MAX_PROPOSAL_THRESHOLD_BPS() external view returns (uint256);
    // function MAX_QUORUM_VOTES_BPS() external view returns (uint256);
    // function MAX_REFUND_PRIORITY_FEE() external view returns (uint256);
    // function MAX_VOTING_DELAY() external view returns (uint256);
    // function MAX_VOTING_PERIOD() external view returns (uint256);
    // function MIN_PROPOSAL_THRESHOLD_BPS() external view returns (uint256);
    // function MIN_QUORUM_VOTES_BPS() external view returns (uint256);
    // function MIN_VOTING_DELAY() external view returns (uint256);
    // function MIN_VOTING_PERIOD() external view returns (uint256);
    // function REFUND_BASE_GAS() external view returns (uint256);
    // function VETOER() external view returns (bytes32);
    // function _acceptAdmin() external;
    // function _addVetoer(address newVetoer) external;
    // function _renouceVetoer() external;
    // function _setPendingAdmin(address newPendingAdmin) external;
    // function setProposalThresholdBPS(uint256 newProposalThresholdBPS) external;
    // function setQuorumVotesBPS(uint256 newQuorumVotesBPS) external;
    // function setVotingDelay(uint256 newVotingDelay) external;
    // function setVotingPeriod(uint256 newVotingPeriod) external;
    // function admin() external view returns (address);
    // function cancel(uint256 proposalId) external;
    // function castRefundableVote(uint256 proposalId_, uint8 support_) external;
    // function castRefundableVoteWithReason(uint256 proposalId_, uint8 support_, string memory reason_) external;
    // function castVote(uint256 proposalId, uint8 support) external;
    // function castVoteBySig(uint256 proposalId, uint8 support, uint8 v, bytes32 r, bytes32 s) external;
    // function castVoteWithReason(uint256 proposalId, uint8 support, string memory reason) external;
    // function execute(uint256 proposalId) external;
    // function getActions(uint256 proposalId)
    //     external
    //     view
    //     returns (
    //         address[] memory targets,
    //         uint256[] memory values,
    //         string[] memory signatures,
    //         bytes[] memory calldatas
    //     );
    function userCommunityScoreData(address) external view returns (uint64 proposalsCreated, uint64 proposalsPassed, uint64 votes);
    function totalCommunityScoreData() external view returns (uint64 proposalsCreated, uint64 proposalsPassed, uint64 votes);
    function updateTotalCommunityScoreData(uint64 _votes, uint64 _proposalsCreated, uint64 _proposalsPassed) external;
    function getProposalData(uint256 id_) external view returns (uint256, address, uint256, uint256);
    // function getProposalStatus(uint256 id_) external view returns (bool, bool, bool);
    // function getProposalVotes(uint256 id_) external view returns (uint256, uint256, uint256);
    function getReceipt(uint256 proposalId, address voter) external view returns (Receipt memory);
    // function getRoleAdmin(bytes32 role) external view returns (bytes32);
    // function grantRole(bytes32 role, address account) external;
    // function hasRole(bytes32 role, address account) external view returns (bool);
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
    // function latestProposalIds(address) external view returns (uint256);
    // function name() external view returns (string memory);
    // function pendingAdmin() external view returns (address);
    // function proposalCount() external view returns (uint256);
    // function proposalMaxOperations() external view returns (uint256);
    // function proposalRefund() external view returns (bool);
    // function proposalThreshold() external view returns (uint256);
    // function proposalThresholdBPS() external view returns (uint256);
    // function propose(
    //     address[] memory targets,
    //     uint256[] memory values,
    //     string[] memory signatures,
    //     bytes[] memory calldatas,
    //     string memory description
    // ) external returns (uint256);
    // function proposeWithRefund(
    //     address[] memory targets,
    //     uint256[] memory values,
    //     string[] memory signatures,
    //     bytes[] memory calldatas,
    //     string memory description
    // ) external returns (uint256);
    // function queue(uint256 proposalId) external;
    // function quorumVotes() external view returns (uint256);
    // function quorumVotesBPS() external view returns (uint256);
    // function renounceRole(bytes32 role, address account) external;
    // function revokeRole(bytes32 role, address account) external;
    // function setProposalRefund(bool _proposing) external;
    function setRefund(RefundStatus _refund) external;
    // function setVotingRefund(bool _voting) external;
    // function staking() external view returns (address);
    // function state(uint256 proposalId) external view returns (uint8);
    // function supportsInterface(bytes4 interfaceId) external view returns (bool);
    // function timelock() external view returns (address);
    // function veto(uint256 proposalId) external;
    // function votingDelay() external view returns (uint256);
    // function votingPeriod() external view returns (uint256);
    // function votingRefund() external view returns (bool);
    function getActiveProposals() external view returns (uint256[] memory);
}
