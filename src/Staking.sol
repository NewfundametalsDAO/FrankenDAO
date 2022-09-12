// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./base/nouns/ERC721Checkpointable.sol";
import "oz/token/ERC721/IERC721.sol";
import "oz/token/ERC721/IERC721Receiver.sol";

/// @title FrankenDAO Staking Contract
/// @author The name of the author
/// @notice Contract for staking FrankenPunks
abstract contract Staking is ERC721Checkpointable {
  // QUESTION: should staked NFTs be nontransferable

  /// @notice Address of the original NFT that will be staked
  address public originalAddress;

  /// @notice Map the tokenID to the block it was staked
  mapping(uint => uint) public blockStaked;

  /// @notice Accepts ownership of a token ID and mints the staked token
  /// @return stakedTokenId id of staked token
  function mint() public virtual returns (uint stakedTokenId);
  //    - contract takes ownership of original ERC721, mints "staked" ERC721
  //    - get metadata from og contract and pass through
  //    - can we use the SVG renderer to add a frame around the original NFT image?
  //    - record block when contract is staked

  /// @notice burns the staked NFT and transfers the original back to msg.sender
  /// @return tokenID the id of the burned/unstaked token
  function burn() public virtual returns (uint tokenID);
  // burn()
  //    - accept staked NFT and burn
  //    - transfer corresponding original NFT to sender
}
