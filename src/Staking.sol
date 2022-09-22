// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "oz/token/ERC721/IERC721.sol";
import "oz/token/ERC721/IERC721Receiver.sol";
import "./interfaces/IFrankenpunks.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IGovernance.sol";

/// @title FrankenDAO Staking Contract
/// @author The name of the author
/// @notice Contract for staking FrankenPunks
abstract contract Staking is ERC721Checkpointable, IStaking {
  IFrankenpunks frankenpunks;
  IGovernance governance;
  address executor;

  mapping(uint => uint) public unlockTime;
  uint public stakeBonusTime = 4 weeks;
  uint public totalVotingPower; // we can't cleanly include community in this?

  uint[40] constant EVIL_BITMAPS; // check if cheaper to make immutable in constructor or insert manually into contract

  /////////////////////////////////
  ////////// CONSTRUCTOR //////////
  /////////////////////////////////

  constructor(address _frankenpunks, uint _stakeBonusTime, address _governance, address _executor) ERC721("Staked FrankenPunks", "sFP") {
    frankenpunks = IFrankenpunks(_frankenpunks);
    stakeBonusTime = _stakeBonusTime;
    governance = _governance;
    executor = _executor;
  }

  /////////////////////////////////
  // OVERRIDE & REVERT TRANSFERS //
  /////////////////////////////////  

  // @todo - make sure this blocks all versions of transferFrom, safeTransferFrom, safeTransfer, etc.
  function _transfer(address from, address to, uint256 tokenId) internal virtual override {
    revert("staked tokens cannot be transferred");
  }

  // @todo - think through rest. i think we leave approvals on so people can stake for one another. mint and burn don't use transfer.

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
      // @todo - no check before they need to have approved this contract to transfer, right?
      frankenpunks.transferFrom(frankenpunks.ownerOf(_tokenId), address(this), _tokenId);
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
      frankenpunks.transferFrom(address(this), _to, _tokenId);
      return getTokenVotingPower(_tokenId, tokenUnlockTime != 0);
  }

    //////////////////////////////////////////////
    ////// ADDED FUNCTIONS FOR VOTING POWER //////
    //////////////////////////////////////////////
    
    function getTokenVotingPower(uint _tokenId, bool _lockUp) public view returns (uint) {
        uint evilPoints = isItEvil(_tokenId) ? 10 : 0;
        return _lockUp ? 40 + evilPoints : 20 + evilPoints;
    }

    function isItEvil(uint _tokenId) internal view returns (bool) {
        // do some testing on this, but loosely, scale it over by tokenId bites and then mask to rightmost bit
        return (EVIL_BITMAP[_tokenId >> 8] >> (_tokenId & 255)) & 1 > 0;
    }

    function getCommunityVotingPower(address _voter) public view returns (uint) {
      if (balanceOf(_voter) == 0) return 0;
      if (delegates(_voter) != address(0)) return 0;

      // uint votesInPastTenProposals = governance.getTotalVotes(_voter) / currentProposalId;
      // uint proposalsToVote = _min(governance.getProposalsToVote(_voter), 10);
      // uint proposalsAccepted = _min(governance.getProposalsAccepted(_voter), 10);
      // return votesInPastTenProposals + 2 * proposalsToVote + 2 * proposalsAccepted;
    }

  /////////////////////////////////
  //////// OWNER OPERATIONS ///////
  /////////////////////////////////

  function changeStakeTime(uint _newStakeBonusTime) public {
    require(_msgSender() == executor, "only executor can change stake time");
    stakeBonusTime = _newStakeBonusTime;
  }


  /////////////////////////////////
  //////////// HELPERS ////////////
  /////////////////////////////////

  function _min(uint a, uint b) internal pure returns(uint) {
    return a < b ? a : b;
  }
}
