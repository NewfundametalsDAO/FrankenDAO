// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { StakingBase } from "../bases/StakingBase.t.sol";

contract TokenURITests is StakingBase {
    // Test that a staked token has a URI.
    function testTokenURI__StakedTokenHasCorrectURI() public {
        uint256 TOKEN_ID = 0;
        string memory TOKEN_ID_STRING = "0";

        mockStakeSingle(TOKEN_ID, 0);

        assert(
            keccak256(bytes(staking.tokenURI(TOKEN_ID))) ==
                keccak256(
                    bytes(
                        string(
                            abi.encodePacked(
                                BASE_TOKEN_URI,
                                TOKEN_ID_STRING,
                                ".json"
                            )
                        )
                    )
                )
        );
    }

    function testTokenURI__StakedMonsterHasCorrectURI() public {
        uint256 TOKEN_ID = 15000;
        string memory TOKEN_ID_STRING = "15000";

        mockStakeSingle(TOKEN_ID, 0);

        assert(
            keccak256(bytes(staking.tokenURI(TOKEN_ID))) ==
                keccak256(
                    bytes(
                        string(
                            abi.encodePacked(
                                BASE_TOKEN_URI,
                                TOKEN_ID_STRING,
                                ".json"
                            )
                        )
                    )
                )
        );
    }

    // Test that the contract URI is set on creation
    function testTokenURI__StakingContractHasContractURI() public {
        assertEq(
            keccak256(bytes(staking.contractURI())),
            keccak256(bytes(CONTRACT_URI))
        );
    }

    // Test that setContractURI updates the contract URI
    function testTokenURI__SetContractURIUpdatesTokenUri() public {
        string memory NEW_CONTRACT_URI = "https://frankenpunks.com/other-uris/";

        vm.prank(COUNCIL_MULTISIG);
        staking.setContractURI(NEW_CONTRACT_URI);

        assertEq(
            keccak256(bytes(staking.contractURI())),
            keccak256(bytes(NEW_CONTRACT_URI))
        );
    }
}
