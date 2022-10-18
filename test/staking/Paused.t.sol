pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../src/Staking.sol";
import "../utils/mocks/Token.sol";

contract PausedTest is Test {
    Staking staking;
    Token frankenpunk;

    function setUp() public { }

    // can still delegate if paused
    //function testDelegatingWhilePaused() public {
        // addr 1 stakes
        // addr 2 stakes
        // pause staking
        // addr 2 delegates to addr 1
    //}
}
