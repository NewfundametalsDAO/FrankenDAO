// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { TestBase } from "../TestBase.t.sol";
import { LibString } from "solmate/utils/LibString.sol";

contract EvilScoresTest is TestBase {

    // Test only exists for sample data, where all evens are evil. Redo with JSON call once we have final.
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
