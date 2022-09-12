pragma solidity ^0.8.10;

interface Staking {
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function DELEGATION_TYPEHASH() external view returns (bytes32);
    function DOMAIN_TYPEHASH() external view returns (bytes32);
    function approve(address to, uint256 tokenId) external;
    function balanceOf(address owner) external view returns (uint256);
    function blockStaked(uint256) external view returns (uint256);
    function burn() external returns (uint256 tokenID);
    function checkpoints(address, uint32) external view returns (uint32 fromBlock, uint96 votes);
    function decimals() external view returns (uint8);
    function delegate(address delegatee) external;
    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external;
    function delegates(address delegator) external view returns (address);
    function getApproved(uint256 tokenId) external view returns (address);
    function getCurrentVotes(address account) external view returns (uint96);
    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function mint() external returns (uint256 stakedTokenId);
    function name() external view returns (string memory);
    function nonces(address) external view returns (uint256);
    function numCheckpoints(address) external view returns (uint32);
    function originalAddress() external view returns (address);
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;
    function setApprovalForAll(address operator, bool approved) external;
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function symbol() external view returns (string memory);
    function tokenByIndex(uint256 index) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function votesToDelegate(address delegator) external view returns (uint96);
}
