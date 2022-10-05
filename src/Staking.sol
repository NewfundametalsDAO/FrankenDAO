// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IFrankenpunks.sol";
import "./interfaces/IStaking.sol";
import "./Governance.sol";
import "./token/ERC721Checkpointable.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "./Refund.sol";

/// @title FrankenDAO Staking Contract
/// @author The name of the author
/// @notice Contract for staking FrankenPunks
abstract contract Staking is ERC721Checkpointable, Refund {
  using Strings for uint256;

  IFrankenPunks frankenpunks;
  Governance governance;
  address executor;

  mapping(uint => uint) public unlockTime; // token => unlock timestamp
  mapping(uint => uint) public stakedTimeBonus; // token => amount of staked bonus they got
  uint public maxStakeBonusTime = 4 weeks;
  uint public maxStakeBonusAmount = 20;

  bool public paused;
  bool public stakingRefund;

  string public _baseTokenURI;
  
  uint[40] EVIL_BITMAPS; // check if cheaper to make immutable in constructor or insert manually into contract

  event StakingPause(bool status);
  event StakingRefundSet(bool status);

  /////////////////////////////////
  ////////// CONSTRUCTOR //////////
  /////////////////////////////////

  constructor(address _frankenpunks, uint _stakeBonusTime, address _governance, address _executor) ERC721("Staked FrankenPunks", "sFP") {
    frankenpunks = IFrankenPunks(_frankenpunks);
    //stakeBonusTime = _stakeBonusTime;
    governance = Governance( _governance );
    executor = _executor;
  }

  /////////////////////////////////
  // OVERRIDE & REVERT TRANSFERS //
  /////////////////////////////////  

  // @todo - make sure this blocks all versions of transferFrom, safeTransferFrom, safeTransfer, etc.
  function _transfer(address _from, address _to, uint256 _tokenId) internal virtual override {
    revert("staked tokens cannot be transferred");
  }

  // @todo - think through rest. i think we leave approvals on so people can stake for one another. mint and burn don't use transfer.

  /////////////////////////////////
  /////// TOKEN URI FUNCTIONS /////
  /////////////////////////////////

  // @todo - we need to create metadata that matches 1-to-1 with old ones token
  // uri of same token should be same but wrapped could do it manually and just
  // redeploy that metadata to IPFS but can we use the SVG renderer to add
  // a frame around the original NFT image?

  function tokenURI(uint256 _tokenId) public view virtual override returns
  (string memory) {
    _requireMinted(_tokenId);

    string memory baseURI = _baseTokenURI;
    return bytes(baseURI).length > 0
      ? string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"))
      : "";
  }

  /////////////////////////////////
  /// STAKE & UNSTAKE FUNCTIONS ///
  /////////////////////////////////

  function stake(uint[] calldata _tokenIds, uint _unlockTime) public {
    _stake(_tokenIds, _unlockTime);
  }

  function stakeWithRefund(uint[] calldata _tokenIds, uint _unlockTime) public {
      uint256 startGas = gasleft();

      uint newVotingPower = _stake(_tokenIds, _unlockTime);

      if (newVotingPower > 0) {
        _refundGas(startGas);
      }
  }

  function _stake(uint[] calldata _tokenIds, uint _unlockTime) internal returns (uint){
      require(!paused, "staking is paused");
      require(_unlockTime == 0 || _unlockTime > block.timestamp, "must lock until future time (or set 0 for unlocked)");

      uint numTokens = _tokenIds.length;
      require(numTokens > 0, "stake at least one token");
      
      uint newVotingPower;
      for (uint i = 0; i < numTokens; i++) {
          newVotingPower += _stakeToken(_tokenIds[i], _unlockTime);
      }
      //votesFromOwnedTokens[owner] += newVotingPower;
      votesFromOwnedTokens[msg.sender] += newVotingPower; // @todo: changed to msg.sender to it compile
      totalVotingPower += newVotingPower;

      return newVotingPower;
  }

  function _stakeToken(uint _tokenId, uint _unlockTime) internal returns(uint) {
      if (_unlockTime > 0) {
        unlockTime[_tokenId] = _unlockTime;
        uint fullStakedTimeBonus = _getStakeLengthBonus(_unlockTime - block.timestamp);
      
        if (_tokenId < 10000) {
          stakedTimeBonus[_tokenId] = fullStakedTimeBonus;
        } else {
          stakedTimeBonus[_tokenId] = fullStakedTimeBonus / 2;
        }
      }

      frankenpunks.transferFrom(frankenpunks.ownerOf(_tokenId), address(this), _tokenId);
      // mint has to be AFTER staked bonus calculation, because it'll pull that in in awarding votes
      _mint(msg.sender, _tokenId); // @todo - or should this be to the owner, or add _to argument to choose?

      return getTokenVotingPower(_tokenId);
  }

  function unstake(uint[] calldata _tokenIds, address _to) public {
    _unstake(_tokenIds, _to);
  }

  function unstakeWithRefund(uint[] calldata _tokenIds, address _to) public {
    uint startGas = gasleft();

    uint lostVotingPower = _unstake(_tokenIds, _to);

    if (lostVotingPower > 0) {
      _refundGas(startGas);
    }
  }

  function _unstake(uint[] calldata _tokenIds, address _to) internal returns (uint){
      uint numTokens = _tokenIds.length;
      require(numTokens > 0, "unstake at least one token");
      
      uint lostVotingPower;
      for (uint i = 0; i < numTokens; i++) {
          lostVotingPower += _unstakeToken(_tokenIds[i], _to);
      }
      votesFromOwnedTokens[msg.sender] -= lostVotingPower;
      totalVotingPower -= lostVotingPower;

      return lostVotingPower;
  }

  function _unstakeToken(uint _tokenId, address _to) internal returns(uint) {
      require(_isApprovedOrOwner(_msgSender(), _tokenId));
      require(unlockTime[_tokenId] < block.timestamp, "token is locked");

      // burn and lostVotingPower calculations have to happen BEFORE bonus is zero'd out, because it pulls that when calculating
      _burn(_tokenId);
      frankenpunks.transferFrom(address(this), _to, _tokenId);
      uint lostVotingPower = getTokenVotingPower(_tokenId);

      unlockTime[_tokenId] = 0;
      stakedTimeBonus[_tokenId] = 0;
      
      return lostVotingPower;
  }

    //////////////////////////////////////////////
    ///// VOTING POWER CALCULATION FUNCTIONS /////
    //////////////////////////////////////////////
    
    function getTokenVotingPower(uint _tokenId) public override view returns (uint) {
      if (_tokenId < 10000) {
        return 20 + stakedTimeBonus[_tokenId] + evilBonus(_tokenId);
      } else {
        return 10 + stakedTimeBonus[_tokenId];
      }
    }
    
    // do some testing on this, but loosely, scale it over by tokenId bites and then mask to rightmost bit
    function evilBonus(uint _tokenId) internal view returns (uint) {
      if (_tokenId >= 10000) return 0; 
      return (EVIL_BITMAPS[_tokenId >> 8] >> (_tokenId & 255)) & 1 * 10;
    }

    function getCommunityVotingPower(address _voter) public override view returns (uint) {
      if (balanceOf(_voter) == 0) return 0;
      if (delegates(_voter) != address(0) && delegates(_voter) != _voter) return 0; // @todo - change to include self depending on decision there

      (uint64 votes, uint64 proposalsCreated, uint64 proposalsPassed) = governance.getCommunityScoreData(_voter);

      return _min(votes, 10) + (2 * _min(proposalsCreated, 10)) + (2 * _min(proposalsPassed, 10));
    }

    // call this when proposals are voted, created, passed, but check thatit's needed first and that they are undelegated
    function incrementTotalCommunityVotingPower(uint _amount) public {
      require(_msgSender() == address(governance), "only governance");
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

  function setPause(bool _paused) external {
    require(_msgSender() == executor, "only executor can pause"); // @todo - change this to multsig
    paused = _paused;
    emit StakingPause(_paused);
  }

  function toggleStakingRefund() external {
    require(_msgSender() == executor, "only executor toggle staking refund"); 

    stakingRefund = !stakingRefund;

    emit StakingRefundSet(stakingRefund);
  }

  function setBaseURI(string calldata baseURI_) external {
    require (_msgSender() == executor, "only executor can set base URI");
    _baseTokenURI = baseURI_;
  }

  /////////////////////////////////
  //////////// HELPERS ////////////
  /////////////////////////////////

  function _min(uint a, uint b) internal pure returns(uint) {
    return a < b ? a : b;
  }

  function _getStakeLengthBonus(uint _stakeLength) internal view returns(uint) {
    return _stakeLength * maxStakeBonusAmount / maxStakeBonusTime;
  }
}
