pragma solidity ^0.8.10;

interface IGovernance {
    event NewAdmin(address oldAdmin, address newAdmin);
    event NewImplementation(address oldImplementation, address newImplementation);
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
    event NewVetoer(address newVetoer);
    event ProposalCanceled(uint256 id);
    event ProposalCreatedWithRequirements(
        uint256 id,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        uint256 proposalThreshold,
        uint256 quorumVotes,
        string description
    );
    event ProposalExecuted(uint256 id);
    event ProposalQueued(uint256 id, uint256 eta);
    event ProposalRefundSet(bool status);
    event ProposalThresholdBPSSet(uint256 oldProposalThresholdBPS, uint256 newProposalThresholdBPS);
    event ProposalVetoed(uint256 id);
    event QuorumVotesBPSSet(uint256 oldQuorumVotesBPS, uint256 newQuorumVotesBPS);
    event RenounceVetoer(address oldVetoer);
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 votes);
    event VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay);
    event VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod);

    event VotingRefundSet(bool status);

    event TotalCommunityScoreDataUpdated(
        uint64 proposalsCreated,
        uint64 proposalsPassed,
        uint64 votes
    );


    struct ProposalTemp {
        uint256 totalSupply;
        uint256 proposalThreshold;
        uint256 latestProposalId;
        uint256 startBlock;
        uint256 endBlock;
    }

    struct CommunityScoreData {
        uint64 proposalsCreated;
        uint64 proposalsPassed;
        uint64 votes;
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
        uint256 startBlock;
        /// @notice The block at which voting ends: votes must be cast prior to this block
        uint256 endBlock;
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
    // function _setProposalThresholdBPS(uint256 newProposalThresholdBPS) external;
    // function _setQuorumVotesBPS(uint256 newQuorumVotesBPS) external;
    // function _setVotingDelay(uint256 newVotingDelay) external;
    // function _setVotingPeriod(uint256 newVotingPeriod) external;
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
        address payable executor_,
        address staking_,
        address founders_,
        address council_,
        uint256 votingPeriod_,
        uint256 votingDelay_,
        uint256 proposalThresholdBPS_,
        uint256 quorumVotesBPS_
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
