pragma solidity ^0.8.10;

interface IGovernance {
    event IssueRefund(address refunded, uint256 ammount, bool sent);
    event NewAdmin(address oldAdmin, address newAdmin);
    event NewImplementation(address oldImplementation, address newImplementation);
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
    event NewVetoer(address newVetoer);
    event ProposalCanceled(uint256 id);
    event ProposalCreated(
        uint256 id,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );
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
    event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 votes, string reason);
    event VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay);
    event VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod);
    event VotingRefundSet(bool status);

    struct Receipt {
        bool hasVoted;
        uint8 support;
        uint96 votes;
    }

    function BALLOT_TYPEHASH() external view returns (bytes32);
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
    function DOMAIN_TYPEHASH() external view returns (bytes32);
    function MAX_PROPOSAL_THRESHOLD_BPS() external view returns (uint256);
    function MAX_QUORUM_VOTES_BPS() external view returns (uint256);
    function MAX_REFUND_PRIORITY_FEE() external view returns (uint256);
    function MAX_VOTING_DELAY() external view returns (uint256);
    function MAX_VOTING_PERIOD() external view returns (uint256);
    function MIN_PROPOSAL_THRESHOLD_BPS() external view returns (uint256);
    function MIN_QUORUM_VOTES_BPS() external view returns (uint256);
    function MIN_VOTING_DELAY() external view returns (uint256);
    function MIN_VOTING_PERIOD() external view returns (uint256);
    function REFUND_BASE_GAS() external view returns (uint256);
    function VETOER() external view returns (bytes32);
    function _acceptAdmin() external;
    function _addVetoer(address newVetoer) external;
    function _renouceVetoer() external;
    function _setPendingAdmin(address newPendingAdmin) external;
    function _setProposalThresholdBPS(uint256 newProposalThresholdBPS) external;
    function _setQuorumVotesBPS(uint256 newQuorumVotesBPS) external;
    function _setVotingDelay(uint256 newVotingDelay) external;
    function _setVotingPeriod(uint256 newVotingPeriod) external;
    function admin() external view returns (address);
    function cancel(uint256 proposalId) external;
    function castRefundableVote(uint256 proposalId_, uint8 support_) external;
    function castRefundableVoteWithReason(uint256 proposalId_, uint8 support_, string memory reason_) external;
    function castVote(uint256 proposalId, uint8 support) external;
    function castVoteBySig(uint256 proposalId, uint8 support, uint8 v, bytes32 r, bytes32 s) external;
    function castVoteWithReason(uint256 proposalId, uint8 support, string memory reason) external;
    function execute(uint256 proposalId) external;
    function getActions(uint256 proposalId)
        external
        view
        returns (
            address[] memory targets,
            uint256[] memory values,
            string[] memory signatures,
            bytes[] memory calldatas
        );
    function getCommunityScoreData(address)
        external
        view
        returns (uint64 proposalsCreated, uint64 proposalsPassed, uint64 votes);
    function getProposalData(uint256 id_) external view returns (uint256, address, uint256, uint256);
    function getProposalStatus(uint256 id_) external view returns (bool, bool, bool);
    function getProposalVotes(uint256 id_) external view returns (uint256, uint256, uint256);
    function getReceipt(uint256 proposalId, address voter) external view returns (Receipt memory);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function hasRole(bytes32 role, address account) external view returns (bool);
    function initialize(
        address timelock_,
        address staking_,
        address[] memory vetoers_,
        uint256 votingPeriod_,
        uint256 votingDelay_,
        uint256 proposalThresholdBPS_,
        uint256 quorumVotesBPS_
    ) external;
    function latestProposalIds(address) external view returns (uint256);
    function name() external view returns (string memory);
    function pendingAdmin() external view returns (address);
    function proposalCount() external view returns (uint256);
    function proposalMaxOperations() external view returns (uint256);
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
            uint256 startBlock,
            uint256 endBlock,
            uint256 forVotes,
            uint256 againstVotes,
            uint256 abstainVotes,
            bool canceled,
            bool vetoed,
            bool executed
        );
    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint256);
    function proposeWithRefund(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint256);
    function queue(uint256 proposalId) external;
    function quorumVotes() external view returns (uint256);
    function quorumVotesBPS() external view returns (uint256);
    function renounceRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function setProposalRefund(bool _proposing) external;
    function setVotingRefund(bool _voting) external;
    function staking() external view returns (address);
    function state(uint256 proposalId) external view returns (uint8);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function timelock() external view returns (address);
    function veto(uint256 proposalId) external;
    function votingDelay() external view returns (uint256);
    function votingPeriod() external view returns (uint256);
    function votingRefund() external view returns (bool);
}
