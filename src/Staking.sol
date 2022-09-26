// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IFrankenpunks.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IGovernance.sol";
import "./token/ERC721Checkpointable.sol";

/// @title FrankenDAO Staking Contract
/// @author The name of the author
/// @notice Contract for staking FrankenPunks
// @todo - add pausable that only impacts staking (not unstaking)
abstract contract Staking is ERC721Checkpointable, IStaking {
  IFrankenPunks frankenpunks;
  IGovernance governance;
  address executor;

  mapping(uint => uint) public unlockTime; // token => unlock timestamp
  mapping(uint => uint) public stakedTimeBonus; // token => amount of staked bonus they got
  uint public maxStakeBonusTime = 4 weeks;
  uint public maxStakeBonusAmount = 20;
  

  uint[40] constant EVIL_BITMAPS; // check if cheaper to make immutable in constructor or insert manually into contract

  /////////////////////////////////
  ////////// CONSTRUCTOR //////////
  /////////////////////////////////

  constructor(address _frankenpunks, uint _stakeBonusTime, address _governance, address _executor) ERC721("Staked FrankenPunks", "sFP") {
    frankenpunks = IFrankenPunks(_frankenpunks);
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

  function stake(uint[] _tokenIds, uint _unlockTime) public {
      uint numTokens = _tokenIds.length;
      require(numTokens > 0, "stake at least one token");
      require(unlockTime == 0 || unlockTime > block.timestamp, "can't lock until past time (set 0 for unlocked)");
      
      uint newVotingPower;
      for (uint i = 0; i < numTokens; i++) {
          newVotingPower += _stakeToken(_tokenIds[i], _unlockTime);
      }
      votesFromOwnedTokens[owner] += newVotingPower;
      totalVotingPower += newVotingPower;
  }

  function _stakeToken(uint _tokenId, uint _unlockTime) internal returns(uint) {
      frankenpunks.transferFrom(frankenpunks.ownerOf(_tokenId), address(this), _tokenId);
      _mint(msg.sender, _tokenId); // @todo - or should this be to the owner, or add _to argument to choose?

      uint stakingBonus = 0;
      if (_unlockTime > 0) {
        unlockTime[tokenId] = _unlockTime;
        stakingBonus = _getStakeLengthBonus(_unlockTime - block.timestamp);
        stakedTimeBonus[tokenId] = stakingBonus;
      }

      return 20 + stakingBonus + evilBonus(_tokenId);
  }

  function unstake(uint[] _tokenIds, address _to) public {
      uint numTokens = _tokenIds.length;
      require(numTokens > 0, "unstake at least one token");
      
      uint lostVotingPower;
      for (uint i = 0; i < numTokens; i++) {
          lostVotingPower += _unstakeToken(_tokenIds[i], _to);
      }
      votesFromOwnedTokens -= lostVotingPower;
      totalVotingPower -= lostVotingPower;
  }

  function _unstakeToken(uint _tokenId, address _to) internal returns(uint) {
      require(_isApprovedOrOwner(_msgSender(), _tokenId));
      require(unlockTime[tokenId] < block.timestamp, "token is locked");

      _burn(_tokenId);
      frankenpunks.transferFrom(address(this), _to, _tokenId);
      
      return getTokenVotingPower(_tokenId);
  }

    //////////////////////////////////////////////
    ////// ADDED FUNCTIONS FOR VOTING POWER //////
    //////////////////////////////////////////////
    
    function getTokenVotingPower(uint _tokenId) public view returns (uint) {
        return 20 + stakedTimeBonus[tokenId] + evilBonus(_tokenId);
    }

    function evilBonus(uint _tokenId) internal view returns (uint) {
        // do some testing on this, but loosely, scale it over by tokenId bites and then mask to rightmost bit
        return (EVIL_BITMAP[_tokenId >> 8] >> (_tokenId & 255)) & 1 * 10;
    }

    function getCommunityVotingPower(address _voter) public view returns (uint) {
      if (balanceOf(_voter) == 0) return 0;
      if (delegates(_voter) != address(0) && delegates(_voter) != _voter) return 0; // @todo - change to include self depending on decision there

      (uint64 votes, uint64 proposalsCreated, uint64 proposalsPassed) = governance.getCommunityScoreData(_voter);

      return _min(votes, 10) + (2 * _min(proposalsCreated, 10)) + (2 * _min(proposalsPassed, 10));
    }

    // call this when proposals are voted, created, passed, but check thatit's needed first and that they are undelegated
    function increaseTotalCommunityVotingPower(uint _amount) public {
      require(_msgSender() == governance, "only governance");
      totalVotingPower += _amount;
    }

  /////////////////////////////////
  //////// OWNER OPERATIONS ///////
  /////////////////////////////////

  function changeStakeTime(uint _newMaxStakeBonusTime) public {
    require(_msgSender() == executor, "only executor can change max stake bonus time");
    maxStakeBonusTime = _newMaxStakeBonusTime;
  }

  function changeStakeAmount(uint _newMaxStakeBonusAmount) public {
    require(_msgSender() == executor, "only executor can change max stake bonus amount");
    maxStakeBonusAmount = _newMaxStakeBonusAmount;
  }


  /////////////////////////////////
  //////////// HELPERS ////////////
  /////////////////////////////////

  function _min(uint a, uint b) internal pure returns(uint) {
    return a < b ? a : b;
  }

  function _getStakeLengthBonus(uint _stakeLength) internal pure returns(uint) {
    return _stakeLength * maxStakeBonusAmount / maxStakeBonusTime;
  }
}
