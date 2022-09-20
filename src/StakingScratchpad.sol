// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../base/nouns/ERC721Checkpointable.sol";

contract StakingScratchpad is ERC721Checkpointable {
    mapping(address => address) private _delegates;
    mapping(address => uint) public communityVotingPower;
    mapping(address => uint) public votes;
    mapping(address => uint) public votesFromOwnedTokens;
    mapping(uint => uint) public unlockTime;

    uint stakeTime = 4 weeks;
    uint totalVotingPower;

    function delegates(address delegator) public view returns (address) {
        address current = _delegates[delegator];
        return current == address(0) ? delegator : current;
    }

    /////////////////////////////////
    /// STAKE & UNSTAKE FUNCTIONS ///
    /////////////////////////////////

    // @notice Accepts ownership of a token ID and mints the staked token
    // @todo - do we want to have multiple lockUp args?
    // @todo - do we want to allow _to address to send stake / unstake?
    function stake(uint[] _tokenIds, bool _lockUp, address _to) public {
        uint numTokens = _tokenIds.length;
        require(numTokens > 0, "stake at least one token");
        // require(numTokens == _lockUp.length, "provide lockup status for each token");
        
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

    function getTokenVotingPower(uint _tokenId, bool _lockUp) public view returns (uint) {
        uint evilPoints = isItEvil(_tokenId) ? 10 : 0;
        return _lockUp ? 40 + evilPoints : 20 + evilPoints;
    }

    function _delegate(address delegator, address delegatee) internal {
        /// @notice differs from `_delegate()` in `Comp.sol` to use `delegates` override method to simulate auto-delegation
        address currentDelegate = delegates(delegator);

        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        uint96 amount = votesToDelegate(delegator);

        _moveDelegates(currentDelegate, delegatee, amount);
    }

    function votesToDelegate(address delegator) public view returns (uint96) {
        return safe96(votesFromOwnedTokens[delegator], 'ERC721Checkpointable::votesToDelegate: amount exceeds 96 bits');
    }
    
    
    // @notice burns the staked NFT and transfers the original back to msg.sender
    function unstake(uint _tokenId, address _to) public {
        // require(msg.sender is owner or approved of tokenId)
        // require(unlockTime[tokenId] < now) // will automatically be correct for 0, if we decide to do that
        // burn tokenId
        // transferFrom(addr(this), _to, tokenId)
        // stakedForTime[tokenId] = false
    }



    //////////////////////////////////////////////
    ////// ADDED FUNCTIONS FOR VOTING POWER //////
    //////////////////////////////////////////////

    uint EVIL_BITMAP;
    uint MASK = 1;

    function isItEvil(uint _tokenId) internal view returns (bool) {
        // do some testing on this, but loosely, scale it over by tokenId bites and then mask to rightmost bit
        return EVIL_BITMAP >> _tokenId & MASK > 0;
    }
}