// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Staking.sol";
import "oz/utils/Strings.sol";

contract StakingTest is Test {
    Staking staking;

    function setUp() public {
        staking = new Staking(
            address(0), //address _frankenpunks, 
            address(0), //address _frankenmonsters,
            address(0), //address _governance, 
            address(0), //address _executor, 
            address(0), //address _founders,
            address(0), //address _council,
            0, //uint _maxStakeBonusTime, 
            0, //uint _maxStakeBonusAmount,
            0, //uint _votesMultiplier, 
            0, //uint _proposalsMultiplier, 
            0 //uint _executedMultiplier
        );
    }

    // Test only exists for sample data, where all evens are evil. Redo with JSON call once we have final.
    function testEvilScores(uint tokenId) public {
        vm.assume(tokenId < 20000);
        if (tokenId > 9999) {
            assert(staking.evilBonus(tokenId) == 0);
        } else {
            string memory json = vm.readFile("static/evilScores.json");
            string memory tokenLookup = string(abi.encodePacked(".", Strings.toString(tokenId)));
            uint correct = abi.decode(vm.parseJson(json, tokenLookup), (uint)) * 10;
            uint bonus = staking.evilBonus(tokenId);
            assert(bonus == correct);
        }        
    }

    // function testGetEvilScores() public {
    //     console.log(staking.evilBonus(2158));
    // }

    // make sure transferFrom blocks all token transfers (safe with both sigs)
    // test evil bonus
}
