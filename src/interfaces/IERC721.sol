pragma solidity ^0.8.13;

interface IERC721 {
    function approve(address spender, uint id) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}
