// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "oz/token/ERC721/ERC721.sol";
import "./Refund.sol";
import "oz/utils/Strings.sol";
import "./interfaces/IFrankenpunks.sol";
import "./interfaces/IStaking.sol";
import "./Governance.sol";

/// @title FrankenDAO Staking Contract
/// @author Zach Obront & Zakk Fleischmann
/// @notice Contract for staking FrankenPunks
abstract contract Staking is ERC721, Refund {
  using Strings for uint256;

  IFrankenPunks frankenpunks;
  Governance governance;
  address executor;

  uint public maxStakeBonusTime;
  uint public maxStakeBonusAmount;

  /////////////////////////////////
  ////////// CONSTRUCTOR //////////
  /////////////////////////////////

  constructor(address _frankenpunks, address _governance, address _executor, uint _maxStakeBonusTime, uint _maxStakeBonusAmount) ERC721("Staked FrankenPunks", "sFP") {
    frankenpunks = IFrankenPunks(_frankenpunks);
    governance = Governance( _governance );
    executor = _executor;
    maxStakeBonusTime = _maxStakeBonusTime; // 4 weeks
    maxStakeBonusAmount = _maxStakeBonusAmount; // 20
  }

  /////////////////////////////////
  //////////// STORAGE ////////////
  /////////////////////////////////

  mapping(uint => uint) public unlockTime; // token => unlock timestamp
  mapping(uint => uint) public stakedTimeBonus; // token => amount of staked bonus they got

  mapping(address => address) private _delegates;
  mapping(address => uint) public votesFromOwnedTokens;
  mapping(address => uint) public votingPower;
  uint public totalTokenVotingPower;

  enum Refund { NoRefunds, StakingRefund, DelegatingRefund, StakingAndDelegatingRefund }
  Refund public refund;

  bool public paused;

  string public _baseTokenURI;

  uint public votesMultiplier = 100;
  uint public proposalsMultiplier = 100;
  uint public executedMultiplier = 100;
  
  uint[40] EVIL_BITMAPS; // @todo check if cheaper to make immutable in constructor or insert manually into contract

  // @todo add all this to the interface instead
  event StakingPause(bool status);
    
  /// @notice An event thats emitted when refunding is set for delegating or staking
  event RefundSet(Refund);

  /// @notice An event thats emitted when an account changes its delegate
  event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

  /// @notice An event thats emitted when a delegate account's vote balance changes
  event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);


  modifier lockedWhileVotesCast(uint[] _tokenIds) {
    uint[] activeProposals = governance.getActiveProposals();
    for (uint i = 0; i < activeProposals.length; i++) {
      require(!governance.getReceipt(activeProposals[i], delegates(msg.sender)).hasVoted, "Staking: Cannot stake while votes are cast");
    }
    _;
  }

  /////////////////////////////////
  // OVERRIDE & REVERT TRANSFERS //
  /////////////////////////////////  

  function _transfer(address _from, address _to, uint256 _tokenId) internal virtual override {
    revert("staked tokens cannot be transferred");
  }

  // @todo - make sure this blocks everything. think through rest. i think we leave approvals on so people can unstake for one another. mint and burn don't use transfer.

  /////////////////////////////////
  /////// TOKEN URI FUNCTIONS /////
  /////////////////////////////////

  function tokenURI(uint256 _tokenId) public view virtual override returns
  (string memory) {
    _requireMinted(_tokenId);

    string memory baseURI = _baseTokenURI;
    return bytes(baseURI).length > 0
      ? string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"))
      : "";
  }
  
  /////////////////////////////////
  /////// DELEGATION LOGIC ////////
  /////////////////////////////////

  function delegates(address delegator) public view returns (address) {
    address current = _delegates[delegator];
    return current == address(0) ? delegator : current;
  }

  function delegate(address delegatee) public {
    if (delegatee == address(0)) delegatee = msg.sender;
    return _delegate(msg.sender, delegatee);
  }

  function delegateWithRefund(address delegatee) public refundable {
    require(refund == Refund.DelegatingRefund || refund == Refund.StakingAndDelegatingRefund, "Staking: Delegating refunds are not enabled");
    if (delegatee == address(0)) delegatee = msg.sender;
    return _delegate(msg.sender, delegatee);
  }

  function _delegate(address delegator, address delegatee) internal lockedWhileVotesCast {
    address currentDelegate = delegates(delegator);
    require(currentDelegate != delegatee, "ERC721Checkpointable::_delegate: already delegated to this address");

    _delegates[delegator] = delegatee == delegator ? address(0) : delegatee;
    uint96 amount = safe96(votesFromOwnedTokens[delegator], 'ERC721Checkpointable::votesToDelegate: amount exceeds 96 bits');
    require(amount > 0, "ERC721Checkpointable::_delegate: amount must be greater than 0");
    
    votingPower[from] -= amount; // @todo is this safe or should i use sub96? do i need to check for addr(0)? i don't think so.
    votingPower[to] += amount; 

    _updateTotalCommunityVotingPower(delegator, currentDelegate, delegatee, amount);
    emit DelegateChanged(delegator, currentDelegate, delegatee);
  }

  // @todo make the gov function, think about if there's a more elegant way to do this.
  function _updateTotalCommunityVotingPower(address delegator, address currentDelegate, address delegatee, uint96 amount) internal {
    if (currentDelegate == delegator) {
      (uint64 votes, uint64 proposalsCreated, uint64 proposalsPassed) = governance.getCommunityScoreData(delegator);
      (uint64 totalVotes, uint64 totalProposalsCreated, uint64 totalProposalsPassed) = governance.totalCommunityVotingPowerBreakdown();
      governance.updateTotalCommunityVotingPowerBreakdown(totalVotes - votes, totalProposalsCreated - proposalsCreated, totalProposalsPassed - proposalsPassed);
    } else if (delegatee == delegator) {
      (uint64 votes, uint64 proposalsCreated, uint64 proposalsPassed) = governance.getCommunityScoreData(delegator);
      (uint64 totalVotes, uint64 totalProposalsCreated, uint64 totalProposalsPassed) = governance.totalCommunityVotingPowerBreakdown();
      governance.updateTotalCommunityVotingPowerBreakdown(totalVotes + votes, totalProposalsCreated + proposalsCreated, totalProposalsPassed + proposalsPassed);
    }
  }

  /////////////////////////////////
  /// STAKE & UNSTAKE FUNCTIONS ///
  /////////////////////////////////

  function stake(uint[] calldata _tokenIds, uint _unlockTime) public {
    _stake(_tokenIds, _unlockTime);
  }

  function stakeWithRefund(uint[] calldata _tokenIds, uint _unlockTime) public refundable {
    require(refund == Refund.StakingRefund || refund == Refund.StakingAndDelegatingRefund, "Staking: Staking refunds are not enabled");
    _stake(_tokenIds, _unlockTime);
  }

  function _stake(uint[] calldata _tokenIds, uint _unlockTime) internal lockedWhileVotesCast {
      require(!paused, "staking is paused");
      require(_unlockTime == 0 || _unlockTime > block.timestamp, "must lock until future time (or set 0 for unlocked)");

      uint numTokens = _tokenIds.length;
      require(numTokens > 0, "stake at least one token");
      
      uint newVotingPower;
      for (uint i = 0; i < numTokens; i++) {
          newVotingPower += _stakeToken(_tokenIds[i], _unlockTime);
      }
      votesFromOwnedTokens[msg.sender] += newVotingPower; // @todo i assumed everything for msg.sender, so approved can do it and they hold it not owner. think through.
      votingPower[delegates(msg.sender)] += newVotingPower;
      totalTokenVotingPower += newVotingPower;
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
      _mint(msg.sender, _tokenId);

      return getTokenVotingPower(_tokenId);
  }

  function unstake(uint[] calldata _tokenIds, address _to) public {
    _unstake(_tokenIds, _to);
  }

  function unstakeWithRefund(uint[] calldata _tokenIds, address _to) public refundable {
    require(refund == Refund.StakingRefund || refund == Refund.StakingAndDelegatingRefund, "Staking: Staking refunds are not enabled");
    _unstake(_tokenIds, _to);
  }

  function _unstake(uint[] calldata _tokenIds, address _to) internal lockedWhileVotesCast {
    uint numTokens = _tokenIds.length;
    require(numTokens > 0, "unstake at least one token");
    
    uint lostVotingPower;
    for (uint i = 0; i < numTokens; i++) {
        lostVotingPower += _unstakeToken(_tokenIds[i], _to);
    }
    votesFromOwnedTokens[msg.sender] -= lostVotingPower;
    votingPower[delegates(msg.sender)] -= lostVotingPower;
    totalTokenVotingPower -= lostVotingPower;
  }

  function _unstakeToken(uint _tokenId, address _to) internal returns(uint) {
    require(_isApprovedOrOwner(msg.sender, _tokenId));
    require(unlockTime[_tokenId] < block.timestamp, "token is locked");

    // burn and lostVotingPower calculations have to happen BEFORE bonus is zero'd out, because it pulls that when calculating
    frankenpunks.transferFrom(address(this), _to, _tokenId);
    uint lostVotingPower = getTokenVotingPower(_tokenId);
    _burn(_tokenId);

    unlockTime[_tokenId] = 0;
    stakedTimeBonus[_tokenId] = 0;
    
    return lostVotingPower;
  }

    //////////////////////////////////////////////
    ///// VOTING POWER CALCULATION FUNCTIONS /////
    //////////////////////////////////////////////
    
    // @todo change getPriorVotes to getVotes in Gov
    function getVotes(address account) public view returns (uint96) {
        return votingPower[account] + getCommunityVotingPower(account);
    }
    
    function getTokenVotingPower(uint _tokenId) public override view returns (uint) {
      if (_tokenId < 10000) {
        return 20 + stakedTimeBonus[_tokenId] + evilBonus(_tokenId);
      } else {
        return 10 + stakedTimeBonus[_tokenId];
      }
    }

    function getCommunityVotingPower(address _voter) public override view returns (uint) {
      uint64 votes;
      uint64 proposalsCreated;
      uint64 proposalsPassed;
      
      if (_voter == type(uint).max) {
        (votes, proposalsCreated, proposalsPassed) = governance.totalCommunityVotingPowerBreakdown();
      } else {
        if (balanceOf(_voter) == 0) return 0;
        if (delegates(_voter) != _voter) return 0;

        (votes, proposalsCreated, proposalsPassed) = governance.getCommunityScoreData(_voter);
      }
      return (votes * VOTES_MULTIPLIER_PERCENT / 100) + (2 * _min(proposalsCreated, 10)) + (2 * _min(proposalsPassed, 10));
    }

    function getTotalVotingPower() public view returns (uint) {
      return totalTokenVotingPower + getCommunityVotingPower(type(uint).max);
    }

    function evilBonus(uint _tokenId) internal view returns (uint) {
      if (_tokenId >= 10000) return 0; 
      return (EVIL_BITMAPS[_tokenId >> 8] >> (_tokenId & 255)) & 1 * 10;
    }


  /////////////////////////////////
  //////// OWNER OPERATIONS ///////
  /////////////////////////////////

  function changeStakeTime(uint _newMaxStakeBonusTime) public {
    require(msg.sender == executor, "only executor can change max stake bonus time");
    maxStakeBonusTime = _newMaxStakeBonusTime;
  }

  function changeStakeAmount(uint _newMaxStakeBonusAmount) public {
    require(msg.sender == executor, "only executor can change max stake bonus amount");
    maxStakeBonusAmount = _newMaxStakeBonusAmount;
  }

  function setPause(bool _paused) external {
    require(msg.sender == executor, "only executor can pause"); // @todo - change this to multsig
    paused = _paused;
    emit StakingPause(_paused);
  }

  function setRefund(Refund refundStatus) external {
    require(msg.sender == executor, "only executor set staking refund"); 
    refund = refundStatus;
    emit RefundSet(refundStatus);
  }

  function setBaseURI(string calldata baseURI_) external {
    require (msg.sender == executor, "only executor can set base URI");
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

  function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
      require(n < 2**32, errorMessage);
      return uint32(n);
  }

  function safe96(uint256 n, string memory errorMessage) internal pure returns (uint96) {
      require(n < 2**96, errorMessage);
      return uint96(n);
  }

  function add96(
      uint96 a,
      uint96 b,
      string memory errorMessage
  ) internal pure returns (uint96) {
      uint96 c = a + b;
      require(c >= a, errorMessage);
      return c;
  }

  function sub96(
      uint96 a,
      uint96 b,
      string memory errorMessage
  ) internal pure returns (uint96) {
      require(b <= a, errorMessage);
      return a - b;
  }
}
