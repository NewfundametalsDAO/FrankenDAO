pragma solidity ^0.8.10;

interface IFrankenDAOExecutor {

}

interface IGovernance {

    ////////////
    // Events //
    ////////////
    event NewAdmin(address oldAdmin, address newAdmin);
    event NewImplementation(address oldImplementation, address newImplementation);
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
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
    event ProposalExecuted(uint256 id);
    event ProposalQueued(uint256 id, uint256 eta);
    event ProposalThresholdSet(uint256 oldProposalThreshold, uint256 newProposalThreshold);
    event ProposalVetoed(uint256 id, address vetoer);
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 votes, string reason);
    event VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay);
    event VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod);
    event WhitelistAccountExpirationSet(address account, uint256 expiration);
    event WhitelistGuardianSet(address oldGuardian, address newGuardian);

    ///////////
    // Proxy //
    ///////////
    function implementation() external view returns (address);

    //////////////
    // Treasury //
    //////////////
    function timelock() external view returns (address);

    /////////////////////
    // Frankenpunk NFT //
    /////////////////////
    function frankenpunk() external view returns (address);

    ///////////////////////////////////////
    // Contract Admin, Vetoer, and Roles //
    ///////////////////////////////////////
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
    function VETOER() external view returns (bytes32);
    function admin() external view returns (address);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function pendingAdmin() external view returns (address);
    function hasRole(bytes32 role, address account) external view returns (bool);
    function grantRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;

    ///////////////
    // Proposals //
    ///////////////
    function initialProposalId() external view returns (uint256);
    function latestProposalIds(address) external view returns (uint256);
    function proposalCount() external view returns (uint256);
    function proposalThreshold() external view returns (uint256);
    function proposals(uint256)
        external
        view
        returns (
            uint256 id,
            address proposer,
            uint256 eta,
            uint256 startBlock,
            uint256 endBlock,
            uint256 forVotes,
            uint256 againstVotes,
            uint256 abstainVotes,
            bool canceled,
            bool executed
        );

    ////////////
    // Voting //
    ////////////
    function calculateVotingPower(address voter) external returns (uint256 votingPower);
    function votingDelay() external view returns (uint256);
    function votingPeriod() external view returns (uint256);

    ///////////////////////
    // EIP 165 Interface //
    ///////////////////////
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
