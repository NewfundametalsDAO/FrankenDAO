pragma solidity ^0.8.10;

interface IStaking {

    ////////////////////
    ////// Events //////
    ////////////////////

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);
    event DelegatingRefundingSet(bool status);
    event IssueRefund(address refunded, uint256 amount, bool sent);
    event NewCouncil(address oldCouncil, address newCouncil);
    event NewFounders(address oldFounders, address newFounders);
    event NewPauser(address oldPauser, address newPauser);
    event NewPendingFounders(address oldPendingFounders, address newPendingFounders);
    event RefundSet(uint8 status);
    event StakingPause(bool status);
    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    ////////////////////
    ////// Errors //////
    ////////////////////

    error NonExistentToken();
    error InvalidDelegation();
    error Paused();
    error InvalidParameter();
    error TokenLocked();
    error StakedTokensCannotBeTransferred();

    /////////////////////
    ////// Storage //////
    /////////////////////

    struct CommunityPowerMultipliers {
        uint64 votes;
        uint64 proposalsCreated;
        uint64 proposalsPassed;
    }

    struct StakingSettings {
        uint128 maxStakeBonusTime;
        uint128 maxStakeBonusAmount;
    }

    enum RefundStatus { 
        StakingAndDelegatingRefund,
        StakingRefund, 
        DelegatingRefund, 
        NoRefunds
    }

    /////////////////////
    ////// Methods //////
    /////////////////////

    function MAX_REFUND_PRIORITY_FEE() external view returns (uint256);
    function REFUND_BASE_GAS() external view returns (uint256);
    function _baseTokenURI() external view returns (string memory);
    function acceptFounders() external;
    function approve(address spender, uint256 id) external;
    function balanceOf(address owner) external view returns (uint256);
    function baseVotes() external view returns (uint256);
    function changeStakeAmount(uint128 _newMaxStakeBonusAmount) external;
    function changeStakeTime(uint128 _newMaxStakeBonusTime) external;
    function communityPowerMultipliers()
        external
        view
        returns (uint64 votes, uint64 proposalsCreated, uint64 proposalsPassed);
    function council() external view returns (address);
    function delegate(address _delegatee) external;
    function delegatingRefund() external view returns (bool);
    function evilBonus(uint256 _tokenId) external view returns (uint256);
    function executor() external view returns (address);
    function founders() external view returns (address);
    function getApproved(uint256) external view returns (address);
    function getCommunityVotingPower(address _voter) external view returns (uint256);
    function getDelegate(address _delegator) external view returns (address);
    function getStakedTokenSupplies() external view returns (uint128, uint128);
    function getTokenVotingPower(uint256 _tokenId) external view returns (uint256);
    function getTotalVotingPower() external view returns (uint256);
    function getVotes(address _account) external view returns (uint256);
    function isApprovedForAll(address, address) external view returns (bool);
    function lastDelegatingRefund(address) external view returns (uint256);
    function lastStakingRefund(address) external view returns (uint256);
    function monsterMultiplier() external view returns (uint256);
    function name() external view returns (string memory);
    function ownerOf(uint256 id) external view returns (address owner);
    function paused() external view returns (bool);
    function pauser() external view returns (address);
    function pendingFounders() external view returns (address);
    function revokeFounders() external;
    function safeTransferFrom(address from, address to, uint256 id) external;
    function safeTransferFrom(address from, address to, uint256 id, bytes memory data) external;
    function setApprovalForAll(address operator, bool approved) external;
    function setBaseURI(string memory _baseURI) external;
    function setBaseVotes(uint256 _baseVotes) external;
    function setCouncil(address _newCouncil) external;
    function setMonsterMultiplier(uint256 _monsterMultiplier) external;
    function setPause(bool _paused) external;
    function setPauser(address _newPauser) external;
    function setPendingFounders(address _newPendingFounders) external;
    function setProposalsCreatedMultiplier(uint64 _proposalsCreatedMultiplier) external;
    function setProposalsPassedMultiplier(uint64 _proposalsPassedMultiplier) external;
    function setRefunds(bool _stakingRefund, bool _delegatingRefund) external;
    function setVotesMultiplier(uint64 _votesmultiplier) external;
    function stake(uint256[] memory _tokenIds, uint256 _unlockTime) external;
    function stakedFrankenMonsters() external view returns (uint128);
    function stakedFrankenPunks() external view returns (uint128);
    function stakingRefund() external view returns (bool);
    function stakingSettings() external view returns (uint128 maxStakeBonusTime, uint128 maxStakeBonusAmount);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
    function tokenVotingPower(address) external view returns (uint256);
    function transferFrom(address, address, uint256) external pure;
    function unlockTime(uint256) external view returns (uint256);
    function unstake(uint256[] memory _tokenIds, address _to) external;
    function votesFromOwnedTokens(address) external view returns (uint256);
}
