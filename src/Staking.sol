// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "solmate/tokens/ERC721.sol";
import "oz/utils/Strings.sol";
import "oz/utils/math/SafeCast.sol";
import "./utils/Refund.sol";
import "./utils/Admin.sol";

import "./interfaces/IERC721.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IGovernance.sol";
import "./interfaces/IExecutor.sol";

/// @title FrankenDAO Staking Contract
/// @author Zach Obront & Zakk Fleischmann
/// @notice Users stake FrankenPunks & FrankenMonsters and get ERC721s in return
/// @notice These ERC721s are used for voting power for FrankenDAO governance
contract Staking is IStaking, ERC721, Refund, Admin {
  using Strings for uint256;
  using SafeCast for uint256;

  /// @notice The original ERC721 FrankenPunks contract
  IERC721 frankenpunks;
  
  /// @notice The original ERC721 FrankenMonsters contract
  IERC721 frankenmonsters;

  /// @notice The DAO governance contract (where voting occurs)
  IGovernance governance;

  /// @return maxStakeBonusTime The maxmimum time you will earn bonus votes for staking for
  /// @return maxStakeBonusAmount The amount of bonus votes you'll get if you stake for the max time
  StakingSettings public stakingSettings;

  /// @notice Multipliers (expressed as percentage) for calculating community voting power from user stats
  /// @return votes The multiplier for extra voting power earned per DAO vote cast
  /// @return proposalsCreated The multiplier for extra voting power earned per proposal created
  /// @return proposalsPassed The multiplier for extra voting power earned per proposal passed
  CommunityPowerMultipliers public communityPowerMultipliers;

  /// @notice Constant to calculate voting power based on multipliers above
  uint constant PERCENT = 100;

  /// @notice Status for which functions (staking, delegating, both, or neither) are refundable
  RefundStatus public refund;

  /// @notice Is staking currently paused or open?
  bool public paused;
  
  /// @notice The allowed unlock time for each staked token (tokenId => timestamp)
  mapping(uint => uint) public unlockTime;

  /// @notice The staked time bonus for each staked token (tokenId => bonus votes)
  /// @dev This needs to be tracked because users will select how much time to lock for, so bonus is variable
  mapping(uint => uint) stakedTimeBonus; 

  /// @notice Addresses that each user delegates votes to
  /// @dev This should only be accessed via delegates() function, which overrides address(0) with self
  mapping(address => address) private _delegates;

  /// @notice The total voting power earned by each user's staked tokens
  /// @dev In other words, this is the amount of voting power that would move if they redelegated
  /// @dev They don't necessarily have this many votes, because they may have delegated them
  mapping(address => uint) public votesFromOwnedTokens;

  /// @notice The total voting power each user has, after adjusting for delegation
  /// @dev This represents the actual token voting power of each user
  mapping(address => uint) public tokenVotingPower;

  /// @notice The total token voting power of the system
  uint totalTokenVotingPower;

  /// @notice Base token URI for the ERC721s representing the staked position
  string public _baseTokenURI;

  /// @notice Bitmaps representing whether each FrankenPunk has a sufficient "evil score" for a bonus.
  /// @dev 40 words * 256 bits = 10,240 bits, which is sufficient to hold values for 10k FrankenPunks
  uint[40] EVIL_BITMAPS = [
    883425322698150530263834307704826599123904599330160270537777278655401984, // 0
    14488147225470816109160058996749687396265978336526515174837584423109802852352, // 1
    38566513062215815139428642218823858442255833421860837338906624, // 2
    105312291668557186697918027683670432324476705909712387428719788032, // 3
    14474011154664524427946373126085988481660077311200856629730921422678596263936, // 4
    3618502788692465607655909614339766499850336868450542774889103259212619972609, // 5
    441711772776714745308416192199486840791445460561420424832198410539892736, // 6
    6901746759773641161995257390185172072446268286034776944761674561224712, // 7
    883423532414903565819785182543377466397133986207912949084155019599544320, // 8
    14474011155086185177904289442148664541270784730116237084843513087002589265920, // 9
    107839786668798718607898896909541540930351713584408019687362806153216, // 10
    904625700641838402593673198335004289144275540958779302917589231213362556944, // 11
    220859253090631447287862539909960206022391538433640386622889848771706880, // 12
    1393839110204029063653915313866451565150208, // 13
    784637716923340670665773318162647287385528792673206407169, // 14
    107839786668602559178668060353525740564723109496935832847049186869248, // 15
    51422802054004612152481822571560984362335820545231474237898784, // 16
    6582018229284824169333500576582381960460086447259084614308728832, // 17
    365732221255902219560809532335122355265736818688, // 18
    445162639419413381705829464770174011933371831432841644599383048677490688, // 19
    6935446280124502090171244984389489167294584349705235353545399909482504, // 20
    452312848583266388373372050675839373643513806386188657447441353755011973120, // 21
    51422023594160337932957247212003666383914706547133656225284128, // 22
    2923003274661805998666646494941077336069228208128, // 23
    215679573337205118357336126271343355406346657833909405071980653182976, // 24
    26959946667150639794667015087041235820865508444839585222888876146720, // 25
    3731581108651760187459529718884681603688140590625042088037390915407571845120, // 26
    33372889303170710042455474178259135664197736114694375141005066752, // 27
    28948022309329151699928351061631107912622119818910282538292189430411643863044, // 28
    55214023430470347690952963241066788995217469738067023806554216123598848, // 29
    55213971185700649632772712790212230970723509677757939395778641765335297, // 30
    50216813883139118038214077107913983031541181002059654103040, // 31
    45671926166601100787582220677640905906662146176, // 32
    431359146674410260659915067596052074490887103277477952745659311325184, // 33
    6741683593362397442763285474207733540211166501858783908538903166976, // 34
    421249166674235107246797774824181756792478284093098635821743865856, // 35
    53919893334350319447007114026840783409769671338355940037889148190720, // 36
    401740641047276407850947922339698016834483256774579142524928, // 37
    220855883097304318299647574273628650268020954052697685772267193358090240, // 38
    0 // 39
  ];

  /////////////////////////////////
  /////////// MODIFIERS ///////////
  /////////////////////////////////

  /// @dev To avoid needing to checkpoint voting power, tokens are locked while users have active votes cast
  /// @dev If a user creates a proposal or casts a vote, this modifier prevents them from unstaking or delegating
  /// @dev Once the proposal is completed, it is removed from getActiveProposals and their tokens are unlocked
  modifier lockedWhileVotesCast() {
    uint[] memory activeProposals = governance.getActiveProposals();
    for (uint i = 0; i < activeProposals.length; i++) {
      if (governance.getReceipt(activeProposals[i], delegates(msg.sender)).hasVoted) revert TokenLocked();
      (, address proposer,,) = governance.getProposalData(activeProposals[i]);
      if (proposer == delegates(msg.sender)) revert TokenLocked();
    }
    _;
  }

  /// @dev The executor sends transactions of successfully passed governance proposals
  modifier onlyExecutor() {
    if (msg.sender != executor) revert NotAuthorized();
    _;
  }

  /////////////////////////////////
  ////////// CONSTRUCTOR //////////
  /////////////////////////////////

  /// @param _frankenpunks The address of the original ERC721 FrankenPunks contract
  /// @param _frankenmonsters The address of the original ERC721 FrankenMonsters contract
  /// @param _governance The address of the DAO governance contract
  /// @param _executor The address of the DAO executor contract
  /// @param _founders The address of the founder multisig for restricted functions
  /// @param _council The address of the council multisig for restricted functions
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
    address _founders,
    address _council,
    uint _maxStakeBonusTime, 
    uint _maxStakeBonusAmount,
    uint _votesMultiplier, 
    uint _proposalsMultiplier, 
    uint _executedMultiplier
  ) ERC721("Staked FrankenPunks", "sFP") {
    frankenpunks = IERC721(_frankenpunks);
    frankenmonsters = IERC721(_frankenmonsters);
    governance = IGovernance( _governance );

    executor = IExecutor(_executor);
    founders = _founders;
    council = _council;

    stakingSettings = StakingSettings({
      maxStakeBonusTime: _maxStakeBonusTime.toUint128(), // 4 weeks
      maxStakeBonusAmount: _maxStakeBonusAmount.toUint128() // 20
    });

    communityPowerMultipliers = CommunityPowerMultipliers({
      votes: _votesMultiplier.toUint64(), // 100
      proposalsCreated: _proposalsMultiplier.toUint64(), // 200
      proposalsPassed: _executedMultiplier.toUint64() //200
    });
  }

  /////////////////////////////////
  // OVERRIDE & REVERT TRANSFERS //
  /////////////////////////////////  

  /// @notice Transferring of staked tokens is prohibited, so all transfers will revert
  /// @dev This will also block safeTransferFrom, because of solmate's implementation
  function transferFrom(address _from, address _to, uint256 _id) public pure override {
    revert("staked tokens cannot be transferred");
  }

  /////////////////////////////////
  /////// TOKEN URI FUNCTIONS /////
  /////////////////////////////////

  /// @notice Token URI to find metadata for each tokenId
  /// @dev The metadata will be a variation on the metadata of the underlying token
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    if (ownerOf(_tokenId) == address(0)) revert NonExistentToken();

    string memory baseURI = _baseTokenURI;
    return bytes(baseURI).length > 0
      ? string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"))
      : "";
  }
  
  /////////////////////////////////
  /////// DELEGATION LOGIC ////////
  /////////////////////////////////

  /// @notice Return the address that a given address delegates to
  /// @param _delegator The address to check 
  /// @return The address that the delegator has delegated to
  /// @dev If the delegator has not delegated, this function will return their own address
  function delegates(address _delegator) public view returns (address) {
    address current = _delegates[_delegator];
    return current == address(0) ? _delegator : current;
  }

  /// @notice Delegate votes to another address
  /// @param _delegatee The address you wish to delegate to
  function delegate(address _delegatee) public {
    if (_delegatee == address(0)) _delegatee = msg.sender;
    return _delegate(msg.sender, _delegatee);
  }

  /// @notice Delegate votes to another address and get your gas cost refunded
  /// @param _delegatee The address you wish to delegate to
  function delegateWithRefund(address _delegatee) public refundable {
    if (refund != RefundStatus.DelegatingRefund || refund != RefundStatus.StakingAndDelegatingRefund) revert NotRefundable();
    if (_delegatee == address(0)) _delegatee = msg.sender;
    return _delegate(msg.sender, _delegatee);
  }

  /// @notice Delegates votes from the sender to the delegatee
  /// @param _delegator The address of the user who called the function and owns the votes being delegated
  /// @param _delegatee The address of the user who will receive the votes
  function _delegate(address _delegator, address _delegatee) internal lockedWhileVotesCast {
    address currentDelegate = delegates(_delegator);
    // If currentDelegate == _delegatee, then this function will not do anything
    if (currentDelegate == _delegatee) revert InvalidDelegation();

    // Set the _delegates mapping to the correct address, subbing in address(0) if they are delegating to themselves
    _delegates[_delegator] = _delegatee == _delegator ? address(0) : _delegatee;
    uint amount = votesFromOwnedTokens[_delegator];

    // If the delegator has no votes, then this function will not do anything
    // This is explicitly blocked to ensure that users without votes cannot abuse the refund mechanism
    if (amount <= 0) revert InvalidDelegation();
    
    // Move the votes from the currentDelegate to the new delegatee
    // Neither of these addresses can be address(0) because: 
    // - currentDelegate calls delegates(), which replaces address(0) with the delegator's address
    // - delegatee is changed to msg.sender in the external functions if address(0) is passed
    tokenVotingPower[currentDelegate] -= amount;
    tokenVotingPower[_delegatee] += amount; 

    // If a user has delegated their votes, then they will have no community voting power
    // This function updates the community voting power totals to ensure they reflect the current reality
    _updateTotalCommunityVotingPower(_delegator, currentDelegate, _delegatee);

    emit DelegateChanged(_delegator, currentDelegate, _delegatee);
  }

  /// @notice Updates the total community voting power totals
  /// @param _delegator The address of the user who called the function and owns the votes being delegated
  /// @param _currentDelegate The address of the user who previously had the votes
  /// @param _delegatee The address of the user who will now receive the votes
  /// @dev This function is called by _delegate, _stake, and _unstake
  /// @dev Because _currentDelegate != _delegatee, we know that at most one of the situations will be true
  function _updateTotalCommunityVotingPower(address _delegator, address _currentDelegate, address _delegatee) internal {
    // If the _delegator current owns their own votes, then they are forfeiting their community voting power
    if (_currentDelegate == _delegator) {
      (uint64 votes, uint64 proposalsCreated, uint64 proposalsPassed) = governance.userCommunityScoreData(_delegator);
      (uint64 totalVotes, uint64 totalProposalsCreated, uint64 totalProposalsPassed) = governance.totalCommunityScoreData();
      governance.updateTotalCommunityScoreData(totalVotes - votes, totalProposalsCreated - proposalsCreated, totalProposalsPassed - proposalsPassed);
    
    // If the new delegator is the new delegatee, they are reclaiming their community voting power
    } else if (_delegatee == _delegator) {
      (uint64 votes, uint64 proposalsCreated, uint64 proposalsPassed) = governance.userCommunityScoreData(_delegator);
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
    if (refund != RefundStatus.StakingRefund || refund != RefundStatus.StakingAndDelegatingRefund) revert NotRefundable();
    _stake(_tokenIds, _unlockTime);
  }

  /// @notice Internal function to stake tokens and get voting power
  /// @param _tokenIds An array of the id of the tokens being staked
  /// @param _unlockTime The timestamp of when the tokens will be unlocked
  function _stake(uint[] calldata _tokenIds, uint _unlockTime) internal {
    if (paused) revert TokenLocked();
    if (_unlockTime == 0) revert InvalidParameter();
    if (_unlockTime < block.timestamp) revert InvalidParameter();

    uint numTokens = _tokenIds.length;
    // This is required to ensure the gas refunds are not abused
    if (numTokens <= 0) revert InvalidParameter();
    
    uint newVotingPower;
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
  function _stakeToken(uint _tokenId, uint _unlockTime) internal returns (uint) {
    if (_unlockTime > 0) {
      unlockTime[_tokenId] = _unlockTime;
      uint fullStakedTimeBonus = (_unlockTime - block.timestamp) * stakingSettings.maxStakeBonusAmount / stakingSettings.maxStakeBonusTime;
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

  /// @notice Internal function to unstake tokens and surrender voting power
  /// @param _tokenIds An array of the ids of the tokens being unstaked
  /// @param _to The address to send the underlying NFT to
  function _unstake(uint[] calldata _tokenIds, address _to) internal lockedWhileVotesCast {
    uint numTokens = _tokenIds.length;
    if (numTokens <= 0) revert InvalidParameter();
    
    uint lostVotingPower;
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
    address owner = ownerOf(_tokenId);
    // NotAuthorized
    if (msg.sender != owner || !isApprovedForAll[owner][msg.sender] || msg.sender != getApproved[_tokenId]) revert NotAuthorized();
    if (unlockTime[_tokenId] >= block.timestamp) revert TokenLocked();

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
    /// @param _account The address of the account to get voting power for
    /// @return The total voting power for the account
    /// @dev This is used by governance to calculate the voting power of an account
    function getVotes(address _account) public view returns (uint) {
        return tokenVotingPower[_account] + getCommunityVotingPower(_account);
    }
    
    /// @notice Get the voting power for a specific token when staking or unstaking
    /// @param _tokenId The id of the token to get voting power for
    /// @return The voting power for the token
    /// @dev Voting power is calculated as 20 + staking bonus (0 to max staking bonus) + evil bonus (0 or 10)
    function getTokenVotingPower(uint _tokenId) public override view returns (uint) {
      if ( ownerOf(_tokenId) == address(0)) revert NonExistentToken();
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
      if (_voter == address(type(uint160).max)) {
        (votes, proposalsCreated, proposalsPassed) = governance.totalCommunityScoreData();
      } else {
        // If a user no longer has any staked tokens, they forfeit their community voting power 
        if (balanceOf(_voter) == 0) return 0;
        // If a user delegates their votes, they forfeit their community voting power
        if (delegates(_voter) != _voter) return 0;

        (votes, proposalsCreated, proposalsPassed) = governance.userCommunityScoreData(_voter);
      }

      CommunityPowerMultipliers memory cpMultipliers = communityPowerMultipliers;
      
      return 
        (votes * cpMultipliers.votes / PERCENT) + 
        (proposalsCreated * cpMultipliers.proposalsCreated / PERCENT) + 
        (proposalsPassed * cpMultipliers.proposalsPassed / PERCENT);
    }

    /// @notice Get the total voting power of the entire system
    /// @return The total votes in the system
    /// @dev This is used to calculate the quorum and proposal thresholds
    function getTotalVotingPower() public view returns (uint) {
      return totalTokenVotingPower + getCommunityVotingPower(address(type(uint160).max));
    }

    /// @notice Get the evil bonus for a given token
    /// @param _tokenId The id of the token to get the evil bonus for
    /// @return The evil bonus for the token
    /// @dev The evil bonus is 10 if the token is sufficiently evil, 0 otherwise
    // @todo switch this back to internal after testing?
    function evilBonus(uint _tokenId) public view returns (uint) {
      if (_tokenId >= 10000) return 0; 
      return (EVIL_BITMAPS[_tokenId >> 8] >> (255 - (_tokenId & 255)) & 1) * 10;
    }

  /////////////////////////////////
  //////// OWNER OPERATIONS ///////
  /////////////////////////////////

  /// @notice Set the max staking time needed to get the max bonus
  /// @param _newMaxStakeBonusTime The new max staking time
  /// @dev This function can only be called by the executor based on a governance proposal
  function changeStakeTime(uint128 _newMaxStakeBonusTime) external onlyExecutor {
    stakingSettings.maxStakeBonusTime = _newMaxStakeBonusTime;
  }

  /// @notice Set the max staking bonus earned if a token is staked for the max time
  /// @param _newMaxStakeBonusAmount The new max staking bonus
  /// @dev This function can only be called by the executor based on a governance proposal
  function changeStakeAmount(uint128 _newMaxStakeBonusAmount) external onlyExecutor {
    stakingSettings.maxStakeBonusAmount = _newMaxStakeBonusAmount;
  }

  /// @notice Turn on or off gas refunds for staking and delegating
  /// @param _refundStatus Are refunds on for staking, delegating, both, or neither?
  function setRefund(RefundStatus _refundStatus) external onlyExecutor {
    emit RefundSet(refund = _refundStatus);
  }

  /// @notice Pause or unpause staking
  /// @param _paused Whether staking should be paused or not
  /// @dev This will be used to open and close staking windows to incentivize participation
  function setPause(bool _paused) external onlyAdmins {
    emit StakingPause(paused = _paused);
  }

  /// @notice Set hte base URI for the metadata for the staked token
  /// @param _baseURI The new base URI
  function setBaseURI(string calldata _baseURI) external onlyAdmins {
    _baseTokenURI = _baseURI;
  }
}
