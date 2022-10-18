pragma solidity ^0.8.13;

interface IStaking {
    // Errors
    error NonExistentToken();
    error InvalidDelegation();
    error Paused();
    error InvalidParameter();
    error TokenLocked();

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
        NoRefunds, 
        StakingRefund, 
        DelegatingRefund, 
        StakingAndDelegatingRefund 
    }

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);
    event DelegatingRefundingSet(bool status);
    event StakingPause(bool status);
    event RefundSet(RefundStatus status);
    
    // function DELEGATION_TYPEHASH() external view returns (bytes32);
    // function DOMAIN_TYPEHASH() external view returns (bytes32);
    // function MAX_REFUND_PRIORITY_FEE() external view returns (uint256);
    // function REFUND_BASE_GAS() external view returns (uint256);
    // function _baseTokenURI() external view returns (string memory);
    // function approve(address to, uint256 tokenId) external;
    // function balanceOf(address owner) external view returns (uint256);
    // function changeStakeAmount(uint256 _newMaxStakeBonusAmount) external;
    // function changeStakeTime(uint256 _newMaxStakeBonusTime) external;
    // function checkpoints(address, uint32) external view returns (uint32 fromBlock, uint votes);
    // function delegate(address delegatee) external;
    // function delegateWithRefund(address delegatee) external;
    // function delegates(address delegator) external view returns (address);
    // function delegatingRefund() external view returns (bool);
    // function getApproved(uint256 tokenId) external view returns (address);
    function getCommunityVotingPower(address _voter) external view returns (uint256);
    // function getCurrentVotes(address account) external view returns (uint);
    // function getPriorVotes(address account, uint256 blockNumber) external view returns (uint);
    function getTokenVotingPower(uint256 _tokenId) external view returns (uint256);
    // function incrementTotalCommunityVotingPower(uint256 _amount) external;
    // function isApprovedForAll(address owner, address operator) external view returns (bool);
    // function maxStakeBonusAmount() external view returns (uint256);
    // function maxStakeBonusTime() external view returns (uint256);
    // function name() external view returns (string memory);
    // function nonces(address) external view returns (uint256);
    // function numCheckpoints(address) external view returns (uint32);
    // function ownerOf(uint256 tokenId) external view returns (address);
    // function paused() external view returns (bool);
    // function safeTransferFrom(address from, address to, uint256 tokenId) external;
    // function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;
    // function setApprovalForAll(address operator, bool approved) external;
    // function setBaseURI(string memory baseURI_) external;
    // function setDelegatingRefund(bool _refunding) external;
    // function setPause(bool _paused) external;
    // function setStakingRefund(bool _staking) external;
    // function stake(uint256[] memory _tokenIds, uint256 _unlockTime) external;
    // function stakeWithRefund(uint256[] memory _tokenIds, uint256 _unlockTime) external;
    // function stakedTimeBonus(uint256) external view returns (uint256);
    // function stakingRefund() external view returns (bool);
    // function supportsInterface(bytes4 interfaceId) external view returns (bool);
    // function symbol() external view returns (string memory);
    // function tokenByIndex(uint256 index) external view returns (uint256);
    // function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    // function tokenURI(uint256 _tokenId) external view returns (string memory);
    // function totalSupply() external view returns (uint256);
    function getTotalVotingPower() external view returns (uint256);
    function getVotes(address account) external view returns (uint);
    // function transferFrom(address from, address to, uint256 tokenId) external;
    // function unlockTime(uint256) external view returns (uint256);
    // function unstake(uint256[] memory _tokenIds, address _to) external;
    // function unstakeWithRefund(uint256[] memory _tokenIds, address _to) external;
    // function votesFromOwnedTokens(address) external view returns (uint256);
    // function votesToDelegate(address delegator) external view returns (uint);
}
