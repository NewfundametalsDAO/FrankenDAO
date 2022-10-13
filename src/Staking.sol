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
/// @notice Users stake FrankenPunks & FrankenMonsters and get ERC721s in return
/// @notice These ERC721s are used to calculate voting power for DAO governance
contract Staking is IStaking, ERC721, Refund {
  using Strings for uint256;

  /// @notice The original ERC721 FrankenPunks contract
  IERC721 frankenpunks;
  
  /// @notice The original ERC721 FrankenMonsters contract
  IERC721 frankenmonsters;

  /// @notice The DAO governance contract (where voting occurs)
  IGovernance governance;

  /// @notice The DAO executor contract (where governance actions are executed)
  address executor;

  /// @param maxStakeBonusTime The maxmimum time you will earn bonus votes for staking for
  /// @param maxStakeBonusAmount The amount of bonus votes you'll get if you stake for the max time
  StakingSettings public stakingSettings;

  /// @notice Multipliers (expressed as percentage) for calculating community voting power from user stats
  /// @param votes The multiplier for extra voting power earned per DAO vote cast
  /// @param proposalsCreated The multiplier for extra voting power earned per proposal created
  /// @param proposalsPassed The multiplier for extra voting power earned per proposal passed
  CommunityPowerMultipliers public communityPowerMultipliers;

  /// @notice Constant to calculate voting power based on multipliers above
  uint constant PERCENT = 100;

  /// @notice Status for which functions (staking, delegating, both, or neither) are refundable
  RefundStatus public refund;

  /// @notice Is staking currently paused or open?
  bool public paused;
  
  /// @notice Bitmaps representing whether each FrankenPunk has a sufficient "evil score" for a bonus.
  /// @dev 40 words * 256 bits = 10,240 bits, which is sufficient to hold values for 10k FrankenPunks
  uint[40] EVIL_BITMAPS;
  
  /// @notice The allowed unlock time for each staked token (tokenId => timestamp)
  mapping(uint => uint) public unlockTime;

  /// @notice The staked time bonus for each staked token (tokenId => bonus votes)
  /// @dev This needs to be tracked because users will select how much time to lock for, so bonus is variable
  mapping(uint => uint) public stakedTimeBonus; 

  /// @notice Addresses that each user delegates votes to
  /// @dev This should only be accessed via delegates() function, which overrides address(0) with self
  mapping(address => address) private _delegates;

  /// @notice The total voting power earned by each user's staked tokens
  /// @dev In other words, this is the amount of voting power that would move if they redelegated
  /// @dev They don't necessarily have this many votes, because they may have delegated them
  mapping(address => uint96) public votesFromOwnedTokens;

  /// @notice The total voting power each user has, after adjusting for delegation
  /// @dev This represents the actual token voting power of each user
  mapping(address => uint96) public tokenVotingPower;

  /// @notice The total token voting power of the system
  uint public totalTokenVotingPower;

  /// @notice Base token URI for the ERC721s representing the staked position
  string public _baseTokenURI;

  /////////////////////////////////
  /////////// MODIFIERS ///////////
  /////////////////////////////////

  /// @dev To avoid needing to checkpoint voting power, tokens are locked while users have active votes cast
  /// @dev If a user creates a proposal or casts a vote, this modifier prevents them from unstaking or delegating
  /// @dev Once the proposal is completed, it is removed from getActiveProposals and their tokens are unlocked
  modifier lockedWhileVotesCast(uint[] _tokenIds) {
    uint[] activeProposals = governance.getActiveProposals();
    for (uint i = 0; i < activeProposals.length; i++) {
      require(!governance.getReceipt(activeProposals[i], delegates(msg.sender)).hasVoted, "Staking: Cannot stake while votes are cast");
      require(!governance.proposals(activeProposals[i]).proposer == delegates(msg.sender), "Staking: Cannot stake while votes are cast");
    }
    _;
  }

  /// @dev The executor sends transactions of successfully passed governance proposals
  modifier onlyExecutor() {
    require(msg.sender == executor, "Staking: only executor");
    _;
  }

  /////////////////////////////////
  ////////// CONSTRUCTOR //////////
  /////////////////////////////////

  /// @param _frankenpunks The address of the original ERC721 FrankenPunks contract
  /// @param _frankenmonsters The address of the original ERC721 FrankenMonsters contract
  /// @param _governance The address of the DAO governance contract
  /// @param _executor The address of the DAO executor contract
  /// @param _maxStakeBonusTime The maxmimum time you will earn bonus votes for staking for
  /// @param _maxStakeBonusAmount The amount of bonus votes you'll get if you stake for the max time
  /// @param _votesMultiplier The multiplier for extra voting power earned per DAO vote cast
  /// @param _proposalsMultiplier The multiplier for extra voting power earned per proposal created
  /// @param _executedMultiplier The multiplier for extra voting power earned per proposal passed
  constructor(
    address _frankenpunks, 
    address _frankenmonsters,
    address _governance, 
    address _executor, 
    uint _maxStakeBonusTime, 
    uint _maxStakeBonusAmount,
    uint _votesMultiplier, 
    uint _proposalsMultiplier, 
    uint _executedMultiplier
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
      votes: _votesMultiplier, // 100
      proposalsCreated: _proposalsMultiplier, // 200
      proposalsPassed: _executedMultiplier //200
    });
  }

  /////////////////////////////////
  // OVERRIDE & REVERT TRANSFERS //
  /////////////////////////////////  

  /// @notice Transferring of staked tokens is prohibited, so all transfers will revert
  /// @dev This will also block safeTransferFrom, because of solmate's implementation
  function transferFrom(address from, address to, uint256 id) public override {
    revert("staked tokens cannot be transferred");
  }

  /////////////////////////////////
  /////// TOKEN URI FUNCTIONS /////
  /////////////////////////////////

  /// @notice Token URI to find metadata for each tokenId
  /// @dev The metadata will be a variation on the metadata of the underlying token
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

  /// @notice Return the address that a given address delegates to
  /// @param delegator The address to check 
  /// @return The address that the delegator has delegated to
  /// @dev If the delegator has not delegated, this function will return their own address
  function delegates(address delegator) public view returns (address) {
    address current = _delegates[delegator];
    return current == address(0) ? delegator : current;
  }

  /// @notice Delegate votes to another address
  /// @param delegatee The address you wish to delegate to
  function delegate(address delegatee) public {
    if (delegatee == address(0)) delegatee = msg.sender;
    return _delegate(msg.sender, delegatee);
  }

  /// @notice Delegate votes to another address and get your gas cost refunded
  /// @param delegatee The address you wish to delegate to
  function delegateWithRefund(address delegatee) public refundable {
    require(
      refund == RefundStatus.DelegatingRefund || refund == RefundStatus.StakingAndDelegatingRefund, 
      "Staking: Delegating refunds are not enabled"
    );
    if (delegatee == address(0)) delegatee = msg.sender;
    return _delegate(msg.sender, delegatee);
  }

  /// @notice Delegates votes from the sender to the delegatee
  /// @param delegator The address of the user who called the function and owns the votes being delegated
  /// @param delegatee The address of the user who will receive the votes
  function _delegate(address delegator, address delegatee) internal lockedWhileVotesCast {
    address currentDelegate = delegates(delegator);
    // If currentDelegate == delegatee, then this function will not do anything
    require(currentDelegate != delegatee, "ERC721Checkpointable::_delegate: already delegated to this address");

    // Set the _delegates mapping to the correct address, subbing in address(0) if they are delegating to themselves
    _delegates[delegator] = delegatee == delegator ? address(0) : delegatee;
    uint96 amount = votesFromOwnedTokens[delegator];

    // If the delegator has no votes, then this function will not do anything
    // This is explicitly blocked to ensure that users without votes cannot abuse the refund mechanism
    require(amount > 0, "ERC721Checkpointable::_delegate: amount must be greater than 0");
    
    // Move the votes from the currentDelegate to the new delegatee
    // Neither of these addresses can be address(0) because: 
    // - currentDelegate calls delegates(), which replaces address(0) with the delegator's address
    // - delegatee is changed to msg.sender in the external functions if address(0) is passed
    tokenVotingPower[currentDelegate] -= amount;
    tokenVotingPower[delegatee] += amount; 

    // If a user has delegated their votes, then they will have no community voting power
    // This function updates the community voting power totals to ensure they reflect the current reality
    _updateTotalCommunityVotingPower(delegator, currentDelegate, delegatee);

    emit DelegateChanged(delegator, currentDelegate, delegatee);
  }

  /// @notice Updates the total community voting power totals
  /// @param delegator The address of the user who called the function and owns the votes being delegated
  /// @param currentDelegate The address of the user who previously had the votes
  /// @param newDelegate The address of the user who will now receive the votes
  /// @dev This function is called by _delegate, _stake, and _unstake
  /// @dev Because currentDelegate != delegatee, we know that at most one of the situations will be true
  function _updateTotalCommunityVotingPower(address delegator, address currentDelegate, address delegatee) internal {
    // If the delegator current owns their own votes, then they are forfeiting their community voting power
    if (currentDelegate == delegator) {
      (uint64 votes, uint64 proposalsCreated, uint64 proposalsPassed) = governance.userCommunityScoreData(delegator);
      (uint64 totalVotes, uint64 totalProposalsCreated, uint64 totalProposalsPassed) = governance.totalCommunityScoreData();
      governance.updateTotalCommunityScoreData(totalVotes - votes, totalProposalsCreated - proposalsCreated, totalProposalsPassed - proposalsPassed);
    
    // If the new delegator is the new delegatee, they are reclaiming their community voting power
    } else if (delegatee == delegator) {
      (uint64 votes, uint64 proposalsCreated, uint64 proposalsPassed) = governance.userCommunityScoreData(delegator);
      (uint64 totalVotes, uint64 totalProposalsCreated, uint64 totalProposalsPassed) = governance.totalCommunityScoreData();
      governance.updateTotalCommunityScoreData(totalVotes + votes, totalProposalsCreated + proposalsCreated, totalProposalsPassed + proposalsPassed);
    }
  }

  /////////////////////////////////
  /// STAKE & UNSTAKE FUNCTIONS ///
  /////////////////////////////////

  /// @notice Stake your tokens to get voting power
  /// @param _tokenIds An array of the id of the token you wish to stake
  /// @param _unlockTime The timestamp of the time your tokens will be unlocked
  /// @dev unlockTime can be set to 0 to stake without locking (and earn no extra staked time bonus)
  function stake(uint[] calldata _tokenIds, uint _unlockTime) public {
    _stake(_tokenIds, _unlockTime);
  }

  /// @notice Stake your tokens to get voting power and get your gas cost refunded
  /// @param _tokenIds An array of the id of the token you wish to stake
  /// @param _unlockTime The timestamp of the time your tokens will be unlocked
  function stakeWithRefund(uint[] calldata _tokenIds, uint _unlockTime) public refundable {
    require(refund == RefundStatus.StakingRefund || refund == RefundStatus.StakingAndDelegatingRefund, "Staking: Staking refunds are not enabled");
    _stake(_tokenIds, _unlockTime);
  }

  /// @notice Internal function to stake tokens and get voting power
  /// @param _tokenIds An array of the id of the tokens being staked
  /// @param _unlockTime The timestamp of when the tokens will be unlocked
  function _stake(uint[] calldata _tokenIds, uint _unlockTime) internal {
    require(!paused, "staking is paused");
    require(_unlockTime == 0 || _unlockTime > block.timestamp, "must lock until future time (or set 0 for unlocked)");

    uint numTokens = _tokenIds.length;
    // This is required to ensure the gas refunds are not abused
    require(numTokens > 0, "stake at least one token");
    
    uint96 newVotingPower;
    for (uint i = 0; i < numTokens; i++) {
        newVotingPower += _stakeToken(_tokenIds[i], _unlockTime);
    }

    votesFromOwnedTokens[msg.sender] += newVotingPower;
    tokenVotingPower[delegates(msg.sender)] += newVotingPower;
    totalTokenVotingPower += newVotingPower;

    // If the user had 0 tokens before and doesn't delegate, they just unlocked their community voting power
    // First, we check if they had 0 tokens before (if their new balance == tokens they just staked)
    if (balanceOf(msg.sender) == numTokens) {
      // Then, we send an update that says the user's delegation went from address(0) to their delegate
      // If their delegate is themselves, this will increase total community voting power accordingly
      // If their tokens are delegated, both conditions will be skipped and nothing will happen
      _updateTotalCommunityVotingPower(msg.sender, address(0), delegates(msg.sender));
    }
  }

  /// @notice Internal function to stake a single token and get voting power
  /// @param _tokenId The id of the token being staked
  /// @param _unlockTime The timestamp of when the token will be unlocked
  function _stakeToken(uint _tokenId, uint _unlockTime) internal returns(uint) {
    if (_unlockTime > 0) {
      unlockTime[_tokenId] = _unlockTime;
      uint fullStakedTimeBonus = (_unlockTime - block.timestamp) * maxStakeBonusAmount / maxStakeBonusTime;
      stakedTimeBonus[_tokenId] = _tokenId < 10000 ? fullStakedTimeBonus : fullStakedTimeBonus / 2;
    }

    // Transfer the underlying token from the owner to this contract
    IERC721 collection = _tokenId < 10000 ? frankenpunks : frankenmonsters;
    collection.transferFrom(collection.ownerOf(_tokenId), address(this), _tokenId);

    // Mint the staker a new ERC721 token representing their staked token
    // This token goes to the address of the user staking, which may not be the underlying token owner
    _mint(msg.sender, _tokenId);

    // Return the voting power for this token based on staked time bonus and evil score
    return getTokenVotingPower(_tokenId);
  }

  /// @notice Unstake your tokens and surrender voting power
  /// @param _tokenIds An array of the ids of the tokens you wish to unstake
  /// @param _to The address to send the underlying NFT to
  function unstake(uint[] calldata _tokenIds, address _to) public {
    _unstake(_tokenIds, _to);
  }

  // function unstakeWithRefund(uint[] calldata _tokenIds, address _to) public refundable {
  //   require(refund == RefundStatus.StakingRefund || refund == RefundStatus.StakingAndDelegatingRefund, "Staking: Staking refunds are not enabled");
  //   _unstake(_tokenIds, _to);
  // }

  /// @notice Internal function to unstake tokens and surrender voting power
  /// @param _tokenIds An array of the ids of the tokens being unstaked
  /// @param _to The address to send the underlying NFT to
  function _unstake(uint[] calldata _tokenIds, address _to) internal lockedWhileVotesCast {
    uint numTokens = _tokenIds.length;
    require(numTokens > 0, "unstake at least one token");
    
    uint96 lostVotingPower;
    for (uint i = 0; i < numTokens; i++) {
        lostVotingPower += _unstakeToken(_tokenIds[i], _to);
    }

    votesFromOwnedTokens[msg.sender] -= lostVotingPower;
    // Since the delegate currently has the voting power, it must be removed from their balance
    // If the user doesn't delegate, delegates(msg.sender) will return self
    tokenVotingPower[delegates(msg.sender)] -= lostVotingPower;
    totalTokenVotingPower -= lostVotingPower;

    // If the user's balance reaches 0, they will not longer have any community voting power
    if (balanceOf(msg.sender) == 0) {
      // We send an update that says their delegation went from their delegate to address(0)
      // If they previously delegated, they didn't have any community voting power, so nothing will happen
      // If they didn't delegate, this will decrease total community voting power accordingly
      _updateTotalCommunityVotingPower(msg.sender, delegates(msg.sender), address(0));
    }
  }

  /// @notice Internal function to unstake a single token and surrender voting power
  /// @param _tokenId The id of the token being unstaked
  /// @param _to The address to send the underlying NFT to
  function _unstakeToken(uint _tokenId, address _to) internal returns(uint) {
    require(_isApprovedOrOwner(msg.sender, _tokenId));
    require(unlockTime[_tokenId] <= block.timestamp, "token is locked");

    // Transfer the underlying asset to the address specified
    IERC721 collection = _tokenId < 10000 ? frankenpunks : frankenmonsters;
    collection.transferFrom(address(this), _to, _tokenId);
    
    // Voting power needs to be calculated before staked time bonus is zero'd out, as it uses this value
    uint lostVotingPower = getTokenVotingPower(_tokenId);
    _burn(_tokenId);

    delete unlockTime[_tokenId];
    delete stakedTimeBonus[_tokenId];
    
    return lostVotingPower;
  }

    //////////////////////////////////////////////
    ///// VOTING POWER CALCULATION FUNCTIONS /////
    //////////////////////////////////////////////
    
    /// @notice Get the total voting power (token + community) for an account
    /// @param account The address of the account to get voting power for
    /// @return The total voting power for the account
    /// @dev This is used by governance to calculate the voting power of an account
    function getVotes(address account) public view returns (uint96) {
        return tokenVotingPower[account] + getCommunityVotingPower(account);
    }
    
    /// @notice Get the voting power for a specific token when staking or unstaking
    /// @param _tokenId The id of the token to get voting power for
    /// @return The voting power for the token
    /// @dev Voting power is calculated as 20 + staking bonus (0 to max staking bonus) + evil bonus (0 or 10)
    function getTokenVotingPower(uint _tokenId) public override view returns (uint) {
      // Only FrankenPunks are eligible for the evil bonus
      if (_tokenId < 10000) {
        return 20 + stakedTimeBonus[_tokenId] + evilBonus(_tokenId);
      } else {
        return 10 + stakedTimeBonus[_tokenId];
      }
    }

    /// @notice Get the community voting power for a given user
    /// @param _voter The address of the account to get community voting power for
    /// @return The community voting power the user currently has
    function getCommunityVotingPower(address _voter) public override view returns (uint) {
      uint64 votes;
      uint64 proposalsCreated;
      uint64 proposalsPassed;
      
      // We allow this function to be called with the max uint value to get the total community voting power
      if (_voter == type(uint).max) {
        (votes, proposalsCreated, proposalsPassed) = governance.totalCommunityScoreData();
      } else {
        // If a user no longer has any staked tokens, they forfeit their community voting power 
        if (balanceOf(_voter) == 0) return 0;
        // If a user delegates their votes, they forfeit their community voting power
        if (delegates(_voter) != _voter) return 0;

        (votes, proposalsCreated, proposalsPassed) = governance.userCommunityScoreData(_voter);
      }

      CommunityPowerMultipliers cpMultipliers = communityPowerMultipliers;
      
      return 
        (votes * cpMultipliers.votes / PERCENT) + 
        (proposalsCreated * cpMultipliers.proposalsCreated / PERCENT) + 
        (proposalsPassed * cpMultipliers.proposalsPassed / PERCENT);
    }

    /// @notice Get the total voting power of the entire system
    /// @returns The total votes in the system
    /// @dev This is used to calculate the quorum and proposal thresholds
    function getTotalVotingPower() public view returns (uint) {
      return totalTokenVotingPower + getCommunityVotingPower(type(uint).max);
    }

    /// @notice Get the evil bonus for a given token
    /// @param _tokenId The id of the token to get the evil bonus for
    /// @return The evil bonus for the token
    /// @dev The evil bonus is 10 if the token is sufficiently evil, 0 otherwise
    function evilBonus(uint _tokenId) internal view returns (uint) {
      if (_tokenId >= 10000) return 0; 
      return (EVIL_BITMAPS[_tokenId >> 8] >> (_tokenId & 255)) & 1 * 10;
    }


  /////////////////////////////////
  //////// OWNER OPERATIONS ///////
  /////////////////////////////////

  /// @notice Set the max staking time needed to get the max bonus
  /// @param _newMaxStakingTime The new max staking time
  /// @dev This function can only be called by the executor based on a governance proposal
  function changeStakeTime(uint _newMaxStakeBonusTime) external onlyExecutor {
    stakingSettings.maxStakeBonusTime = _newMaxStakeBonusTime;
  }

  /// @notice Set the max staking bonus earned if a token is staked for the max time
  /// @param _newMaxStakeBonusAmount The new max staking bonus
  /// @dev This function can only be called by the executor based on a governance proposal
  function changeStakeAmount(uint _newMaxStakeBonusAmount) external onlyExecutor {
    stakingSettings.maxStakeBonusAmount = _newMaxStakeBonusAmount;
  }

  /// @notice Pause or unpause staking
  /// @param _paused Whether staking should be paused or not
  /// @dev This will be used to open and close staking windows to incentivize participation
  function setPause(bool _paused) external onlyExecutor { // @todo This will probably switch to be admins
    emit StakingPause(paused = _paused);
  }

  /// @notice Turn on or off gas refunds for staking and delegating
  /// @param _refundStatus Are refunds on for staking, delegating, both, or neither?
  function setRefund(Refund _refundStatus) external onlyExecutor {
    emit RefundSet(refund = _refundStatus);
  }

  /// @notice Set hte base URI for the metadata for the staked token
  /// @param baseURI_ The new base URI
  function setBaseURI(string calldata baseURI_) external onlyExecutor {
    _baseTokenURI = baseURI_;
  }
}