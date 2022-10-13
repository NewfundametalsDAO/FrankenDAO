// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "solmate/tokens/ERC721.sol";
import "oz/utils/Strings.sol";
import "./utils/Refund.sol";
import "./utils/Admin.sol";

import "./interfaces/IERC721.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IGovernance.sol";

/// @title FrankenDAO Staking Contract
/// @author Zach Obront & Zakk Fleischmann
/// @notice Contract for staking FrankenPunks & calculating voting power for governance
contract Staking is IStaking, ERC721, Refund, Admin {
  using Strings for uint256;

  IERC721 frankenpunks;
  IERC721 frankenmonsters;
  IGovernance governance;
  address executor;


  StakingSettings public stakingSettings;
  CommunityPowerMultipliers public communityPowerMultipliers;
  RefundStatus public refund;
  bool public paused;
  
  uint[40] EVIL_BITMAPS; // @todo check if cheaper to make immutable in constructor or insert manually into contract

  mapping(uint => uint) public unlockTime; // token => unlock timestamp
  mapping(uint => uint) public stakedTimeBonus; // token => amount of staked bonus they got

  mapping(address => address) private _delegates;
  mapping(address => uint96) public votesFromOwnedTokens;
  mapping(address => uint96) public tokenVotingPower;
  uint public totalTokenVotingPower;

  string public _baseTokenURI;

  /////////////////////////////////
  /////////// MODIFIERS ///////////
  /////////////////////////////////

  // @todo test if it's cheaper to just send back all data from governance once
  modifier lockedWhileVotesCast(uint[] _tokenIds) {
    uint[] activeProposals = governance.getActiveProposals();
    for (uint i = 0; i < activeProposals.length; i++) {
      require(!governance.getReceipt(activeProposals[i], delegates(msg.sender)).hasVoted, "Staking: Cannot stake while votes are cast");
      require(!governance.proposals(activeProposals[i]).proposer == delegates(msg.sender), "Staking: Cannot stake while votes are cast");
    }
    _;
  }

  /////////////////////////////////
  ////////// CONSTRUCTOR //////////
  /////////////////////////////////

  constructor(
    address _frankenpunks, 
    address _frankenmonsters,
    address _governance, 
    address _executor, 
    uint _maxStakeBonusTime, 
    uint _maxStakeBonusAmount,
    uint initialVotesMultiplier, 
    uint initialProposalsMultiplier, 
    uint initialExecutedMultiplier
  ) ERC721("Staked FrankenPunks", "sFP") {
    frankenpunks = IERC721(_frankenpunks);
    frankenmonsters = IERC721(_frankenmonsters);
    governance = IGovernance( _governance );
    executor = _executor;

    stakingSettings = StakingSettings({
      maxStakeBonusTime: _maxStakeBonusTime, // 4 weeks
      maxStakeBonusAmount: _maxStakeBonusAmount // 20
    });

    communityPowerMultipliers = CommunityPowerMultipliers({
      votes: initialVotesMultiplier, // 100
      proposalsCreated: initialProposalsMultiplier, // 200
      proposalsPassed: initialExecutedMultiplier //200
    });
  }

  /////////////////////////////////
  // OVERRIDE & REVERT TRANSFERS //
  /////////////////////////////////  

  // @todo - make sure this blocks everything. think through rest. i think we leave approvals on so people can unstake for one another. mint and burn don't use transfer.
  function _transfer(address _from, address _to, uint256 _tokenId) internal virtual override {
    revert("staked tokens cannot be transferred");
  }

  /////////////////////////////////
  /////// TOKEN URI FUNCTIONS /////
  /////////////////////////////////

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
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
    require(
      refund == RefundStatus.DelegatingRefund || refund == RefundStatus.StakingAndDelegatingRefund, 
      "Staking: Delegating refunds are not enabled"
    );
    if (delegatee == address(0)) delegatee = msg.sender;
    return _delegate(msg.sender, delegatee);
  }

  function _delegate(address delegator, address delegatee) internal lockedWhileVotesCast {
    address currentDelegate = delegates(delegator);
    require(currentDelegate != delegatee, "ERC721Checkpointable::_delegate: already delegated to this address");

    _delegates[delegator] = delegatee == delegator ? address(0) : delegatee;
    uint96 amount = votesFromOwnedTokens[delegator];
    require(amount > 0, "ERC721Checkpointable::_delegate: amount must be greater than 0");
    
    tokenVotingPower[currentDelegate] -= amount;
    tokenVotingPower[delegatee] += amount; 

    _updateTotalCommunityVotingPower(delegator, currentDelegate, delegatee);
    emit DelegateChanged(delegator, currentDelegate, delegatee);
  }

  // @todo rename functions?
  function _updateTotalCommunityVotingPower(address delegator, address currentDelegate, address delegatee) internal {
    if (currentDelegate == delegator) {
      (uint64 votes, uint64 proposalsCreated, uint64 proposalsPassed) = governance.getCommunityScoreData(delegator);
      (uint64 totalVotes, uint64 totalProposalsCreated, uint64 totalProposalsPassed) = governance.totalCommunityVotingPowerBreakdown();
      // Can't underflow. Totals will always be higher than individual scores.
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
    require(refund == RefundStatus.StakingRefund || refund == RefundStatus.StakingAndDelegatingRefund, "Staking: Staking refunds are not enabled");
    _stake(_tokenIds, _unlockTime);
  }

  function _stake(uint[] calldata _tokenIds, uint _unlockTime) internal {
      require(!paused, "staking is paused");
      require(_unlockTime == 0 || _unlockTime > block.timestamp, "must lock until future time (or set 0 for unlocked)");

      uint numTokens = _tokenIds.length;
      require(numTokens > 0, "stake at least one token");
      
      uint96 newVotingPower;
      for (uint i = 0; i < numTokens; i++) {
          newVotingPower += _stakeToken(_tokenIds[i], _unlockTime);
      }
      votesFromOwnedTokens[msg.sender] += newVotingPower;
      tokenVotingPower[delegates(msg.sender)] += newVotingPower;
      totalTokenVotingPower += newVotingPower;

      if (balanceOf(msg.sender) == numTokens) {
        _updateTotalCommunityVotingPower(msg.sender, address(0), delegates(msg.sender));
      }
  }

  function _stakeToken(uint _tokenId, uint _unlockTime) internal returns(uint) {
      if (_unlockTime > 0) {
        unlockTime[_tokenId] = _unlockTime;
        uint fullStakedTimeBonus = (_unlockTime - block.timestamp) * maxStakeBonusAmount / maxStakeBonusTime;
        stakedTimeBonus[_tokenId] = _tokenId < 10000 ? fullStakedTimeBonus : fullStakedTimeBonus / 2;
      }

      IERC721 collection = _tokenId < 10000 ? frankenpunks : frankenmonsters;
      collection.transferFrom(collection.ownerOf(_tokenId), address(this), _tokenId);
      _mint(msg.sender, _tokenId);

      return getTokenVotingPower(_tokenId);
  }

  function unstake(uint[] calldata _tokenIds, address _to) public {
    _unstake(_tokenIds, _to);
  }

  // @todo ask them: probably don't want to make unstake refundable?
  // function unstakeWithRefund(uint[] calldata _tokenIds, address _to) public refundable {
  //   require(refund == RefundStatus.StakingRefund || refund == RefundStatus.StakingAndDelegatingRefund, "Staking: Staking refunds are not enabled");
  //   _unstake(_tokenIds, _to);
  // }

  function _unstake(uint[] calldata _tokenIds, address _to) internal lockedWhileVotesCast {
    uint numTokens = _tokenIds.length;
    require(numTokens > 0, "unstake at least one token");
    
    uint96 lostVotingPower;
    for (uint i = 0; i < numTokens; i++) {
        lostVotingPower += _unstakeToken(_tokenIds[i], _to);
    }
    votesFromOwnedTokens[msg.sender] -= lostVotingPower;
    tokenVotingPower[delegates(msg.sender)] -= lostVotingPower;
    totalTokenVotingPower -= lostVotingPower;

    if (balanceOf(msg.sender) == 0) {
      _updateTotalCommunityVotingPower(msg.sender, delegates(msg.sender), address(0));
    }
  }

  function _unstakeToken(uint _tokenId, address _to) internal returns(uint) {
    require(_isApprovedOrOwner(msg.sender, _tokenId));
    require(unlockTime[_tokenId] <= block.timestamp, "token is locked");

    // burn and lostVotingPower calculations have to happen BEFORE bonus is zero'd out, because it pulls that when calculating
    IERC721 collection = _tokenId < 10000 ? frankenpunks : frankenmonsters;
    collection.transferFrom(address(this), _to, _tokenId);
    uint lostVotingPower = getTokenVotingPower(_tokenId);
    _burn(_tokenId);

    unlockTime[_tokenId] = 0;
    stakedTimeBonus[_tokenId] = 0;
    
    return lostVotingPower;
  }

    //////////////////////////////////////////////
    ///// VOTING POWER CALCULATION FUNCTIONS /////
    //////////////////////////////////////////////
    
    function getVotes(address account) public view returns (uint96) {
        return tokenVotingPower[account] + getCommunityVotingPower(account);
    }
    
    function getTokenVotingPower(uint _tokenId) public override view returns (uint) {
      // @todo confirm the exact token numbers with them. punks go to 9999?
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
      CommunityPowerMultipliers cpMultipliers = communityPowerMultipliers;
      return (votes * cpMultipliers.votes / 100) + (proposalsCreated * cpMultipliers.proposalsCreated / 100) + (proposalsPassed * cpMultipliers.proposalsPassed / 100);
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
  
  // @todo ask them: divide these up between multisig, executor, or either

  function changeStakeTime(uint _newMaxStakeBonusTime) public {
    require(msg.sender == executor, "only executor can change max stake bonus time");
    stakingSettings.maxStakeBonusTime = _newMaxStakeBonusTime;
  }

  function changeStakeAmount(uint _newMaxStakeBonusAmount) public {
    require(msg.sender == executor, "only executor can change max stake bonus amount");
    stakingSettings.maxStakeBonusAmount = _newMaxStakeBonusAmount;
  }

  function setPause(bool _paused) external {
    require(msg.sender == executor, "only executor can pause"); 
    paused = _paused;
    emit StakingPause(_paused);
  }

  function setRefund(Refund _refundStatus) external {
    require(msg.sender == executor, "only executor set staking refund"); 
    refund = _refundStatus;
    emit RefundSet(_refundStatus);
  }

  function setBaseURI(string calldata baseURI_) external {
    require(msg.sender == executor, "only executor can set base URI");
    _baseTokenURI = baseURI_;
  }
}