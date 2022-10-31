// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { TestBase } from "../bases/TestBase.t.sol";
import { LibString } from "solmate/utils/LibString.sol";

contract EvilScoreTests is TestBase {

    // Test that all evil scores pulled from on chain match with the local JSON file.
    function testEvilScores(uint tokenId) public {
        vm.assume(tokenId < 20000);
        if (tokenId > 9999) {
            assert(staking.evilBonus(tokenId) == 0);
        } else {
            string memory json = vm.readFile("static/evilScores.json");
            string memory tokenLookup = string(abi.encodePacked(".", LibString.toString(tokenId)));
            uint correct = abi.decode(vm.parseJson(json, tokenLookup), (uint)) * 10;
            uint bonus = staking.evilBonus(tokenId);
            assert(bonus == correct);
        }        
    }
}
