// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "oz/token/ERC721/IERC721.sol";
import "oz/token/ERC721/IERC721Receiver.sol";
import { IFrankenpunks } from "./interfaces/IFrankenpunks.sol";
import "./interfaces/IStaking.sol";

/// @title FrankenDAO Staking Contract
/// @author The name of the author
/// @notice Contract for staking FrankenPunks
abstract contract Staking is ERC721Checkpointable, IStaking {
  /// @notice Address of the original NFT that will be staked
  IFrankenpunks public frankenpunks;
  address governance;

  mapping(uint => uint) public unlockTime;
  uint public stakeBonusTime = 4 weeks;
  uint totalVotingPower;

  /////////////////////////////////
  ////////// CONSTRUCTOR //////////
  /////////////////////////////////

  // @todo - governance should be executor - rename?
  constructor(address _frankenpunks, uint _stakeBonusTime, address _governance) ERC721("Staked FrankenPunks", "sFP") {
    frankenpunks = IFrankenpunks(_frankenpunks);
    stakeBonusTime = _stakeBonusTime;
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
    // @todo - do we want to have multiple lockUp args? require(numTokens == _lockUp.length, "provide lockup status for each token");
    // @todo - do we want to allow _to address to send stake / unstake?
  function stake(uint[] _tokenIds, bool _lockUp, address _to) public {
      uint numTokens = _tokenIds.length;
      require(numTokens > 0, "stake at least one token");
      
      uint newVotingPower;
      for (uint i = 0; i < numTokens; i++) {
          newVotingPower += _stakeToken(_tokenIds[i], _lockUp, _to);
      }
      votes[delegates(owner)] += newVotingPower;
      votesFromOwnedTokens[owner] += newVotingPower;
      totalVotingPower += newVotingPower;
  }

  function _stakeToken(uint _tokenId, bool _lockUp, address _to) internal returns(uint) {
      require(_isApprovedOrOwner(_msgSender(), _tokenId));
      transferFrom(ownerOf(_tokenId), address(this), _tokenId);
      _mint(_to, _tokenId);
      if (_lockUp) unlockTime[tokenId] = now + stakeTime;
      return getTokenVotingPower(_tokenId, _lockUp);
  }

  function unstake(uint[] _tokenIds, address _to) public {
      uint numTokens = _tokenIds.length;
      require(numTokens > 0, "unstake at least one token");
      
      uint lostVotingPower;
      for (uint i = 0; i < numTokens; i++) {
          lostVotingPower += _unstakeToken(_tokenIds[i], _to);
      }
      votes[delegates(owner)] -= lostVotingPower;
      votesFromOwnedTokens -= lostVotingPower;
      totalVotingPower -= lostVotingPower;
  }

  function _unstakeToken(uint _tokenId, address _to) internal returns(uint) {
      require(_isApprovedOrOwner(_msgSender(), _tokenId));
      uint tokenUnlockTime = unlockTime[tokenId];
      require(tokenUnlockTime < now, "token is locked");
      _burn(_tokenId);
      transferFrom(address(this), _to, _tokenId);
      return getTokenVotingPower(_tokenId, tokenUnlockTime != 0);
  }

    //////////////////////////////////////////////
    ////// ADDED FUNCTIONS FOR VOTING POWER //////
    //////////////////////////////////////////////
    
    function getTokenVotingPower(uint _tokenId, bool _lockUp) public view returns (uint) {
        uint evilPoints = isItEvil(_tokenId) ? 10 : 0;
        return _lockUp ? 40 + evilPoints : 20 + evilPoints;
    }
    
    uint EVIL_BITMAP;
    uint MASK = 1;

    function isItEvil(uint _tokenId) internal view returns (bool) {
        // do some testing on this, but loosely, scale it over by tokenId bites and then mask to rightmost bit
        return EVIL_BITMAP >> _tokenId & MASK > 0;
    }

    /////////////////////////////////
  //////// OWNER OPERATIONS ///////
  /////////////////////////////////

  function changeStakeTime(uint _newStakeBonusTime) public {
    require(_msgSender() == governance, "only governance can change stake time");
    stakeBonusTime = _newStakeBonusTime;
  }
}
