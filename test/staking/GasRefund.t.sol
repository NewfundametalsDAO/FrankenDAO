pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "../../src/Staking.sol";
import "../utils/mocks/Token.sol";

contract GasRefundingTest is Test {
    Staking staking;
    Token frankenpunk;

    function setUp() public {

    }
    // set refunding
    // function testSettingRefund() public {
        // assert refund = StakingAndDelegatingRefund
        // set refund to DelegatingRefund
        // assert eq DelegatingRefund
        // set refund to StakingRefund
        // assert eq StakingRefund
    // }
    // gas refunded for staking
    // function testRefundingForStaking() {
        // get starting balance of addr 1
        // stake tokens
        // get new balance
        // assert eq starting balance, new balance;
    // }

    // gas refunded for unstaking
    // function testRefundingForUnstaking() {
        // stake token
        // get starting balance of addr 1
        // unstake token
        // get new balance
        // assert eq starting balance, new balance;
    // }

    // gas refunded for delegating
    // function testRefundingForDelegating() {
        // get starting balance of addr 1
        // delegate
        // get new balance
        // assert eq starting balance, new balance;
    // }

    // unset refunding
    // delegating reverts if refunding is paused
    // staking reverts if refunding is paused
    // unstaking reverts if refunding is paused
    // function testRefundableMethodsRevertIfRefundingIsPaused() {
        // set refund to NoRefunds;
        // expect revert: delegateWithRefund;
        // expect revert: stakingWithRefund;
        // expect revert: unstakingWithRefund;
    // }

    // staking reverts if contract has insufficient balance
    // delegating reverts if contract has insufficient balance
    // unstaking reverts if contract has insufficient balance
    // function testRefundableMethodsRevertIfInsufficientBalance() {
        // set staking balance to zero
        // expect revert: delegateWithRefund;
        // expect revert: stakingWithRefund;
        // expect revert: unstakingWithRefund;
    // }
}
