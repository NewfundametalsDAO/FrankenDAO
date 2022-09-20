// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./base/nouns/ERC721Checkpointable.sol";
import "oz/token/ERC721/IERC721.sol";
import "oz/token/ERC721/IERC721Receiver.sol";
import { IFrankenpunks } from  "./interfaces/IFrankenpunks.sol";

/// @title FrankenDAO Staking Contract
/// @author The name of the author
/// @notice Contract for staking FrankenPunks
abstract contract Staking is ERC721Checkpointable {
  /// @notice Address of the original NFT that will be staked
  IFrankenpunks public frankenpunks;

  address governance;

  /// @notice Map the tokenID to the block it's allowed to be unstaked
  // changed this from stakedBlock to unlockTime so we don't need to do any math
  mapping(uint => uint) public unlockTime;

  mapping(uint => bool) public stakedForTime;

  uint public stakeTime;

  /////////////////////////////////
  ////////// CONSTRUCTOR //////////
  /////////////////////////////////

  constructor(address _frankenpunks, uint _stakeTime, address _governance) ERC721("Staked FrankenPunks", "sFP") {
    frankenpunks = IFrankenpunks(_frankenpunks);
    stakeTime = _stakeTime;
    governance = _governance;
  }

  /////////////////////////////////
  // OVERRIDE & REVERT TRANSFERS //
  /////////////////////////////////

  // should be nontransferrable because otherwise it's not really staked, they can just trade these
  // don't forget to do all the different types of inputs, or else users can sneak around it by inputting bytes manually
  // the only transfers allowed should be internal ones called by stake and unstake functions
  // should be transferFrom, safeTransferFrom x 2, safeTransfer, check if there are others?
  // think through rest. i think we leave approvals on so people can stake for one another.
  // no new functions here for interface, just a note for us to do this later


  /////////////////////////////////
  /////// TOKEN URI FUNCTIONS /////
  /////////////////////////////////

  // we need to create metadata that matches 1-to-1 with old ones
  // token uri of same token should be same but wrapped
  // could do it manually and just redeploy that metadata to IPFS
  // but can we use the SVG renderer to add a frame around the original NFT image?

  /////////////////////////////////
  /// STAKE & UNSTAKE FUNCTIONS ///
  /////////////////////////////////

  // @notice Accepts ownership of a token ID and mints the staked token
  function stake(address _from, uint _tokenId, bool _lockUp) public {
    // transferFrom(from, addr(this), tokenId)
    // mint(from, tokenId) => mint same tokenId from this contract as the one they staked
    // if lockUp, unlockTime[tokenId] = now + stakeTime, else unlockTime[tokenId] = now
    // question: any downside to making the else "0" instead of now, and checking for that in unstake to save gas?
    // if lockUp, set stakedForTime[tokenId] = true
  }
  
  // @notice burns the staked NFT and transfers the original back to msg.sender
  function unstake(uint _tokenId, address _to) public {
    // require(msg.sender is owner or approved of tokenId)
    // require(unlockTime[tokenId] < now) // will automatically be correct for 0, if we decide to do that
    // burn tokenId
    // transferFrom(addr(this), _to, tokenId)
    // stakedForTime[tokenId] = false
  }

  /////////////////////////////////
  //////// OWNER OPERATIONS ///////
  /////////////////////////////////

  function changeStakeTime(uint _newStakeTime) public {
    // require(only governance can change this)
    // stakeTime = _newStakeTime;
  }
}
