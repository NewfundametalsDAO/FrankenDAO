// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { StakingBase } from "../bases/StakingBase.t.sol";

contract TokenURITests is StakingBase {
    // Test that a staked token has a URI.
    function testTokenURI__StakedTokenHasCorrectURI() public {
        uint TOKEN_ID = 0;
        string memory TOKEN_ID_STRING = "0";

        mockStakeSingle(TOKEN_ID, 0);

        assert(
            keccak256(bytes(staking.tokenURI(TOKEN_ID))) == 
            keccak256(bytes(string(abi.encodePacked(BASE_TOKEN_URI, TOKEN_ID_STRING, ".json"))))
        );
    }

    function testTokenURI__StakedMonsterHasCorrectURI() public {
        uint TOKEN_ID = 15000;
        string memory TOKEN_ID_STRING = "15000";

        mockStakeSingle(TOKEN_ID, 0);
        
        assert(
            keccak256(bytes(staking.tokenURI(TOKEN_ID))) == 
            keccak256(bytes(string(abi.encodePacked(BASE_TOKEN_URI, TOKEN_ID_STRING, ".json"))))
        );
    }
}
