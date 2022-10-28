// pragma solidity ^0.8.13;

// import "forge-std/Test.sol";
// import "./mocks/Token.sol";
// import "../../src/Staking.sol";
// import "../../src/Governance.sol";
// import "../../src/Executor.sol";

// contract BaseSetup is Test {
//     address founders;
//     address council;

//     Governance governance;
//     Executor executor;
//     Staking staking;

//     Token frankenpunk;
//     Token frankenmonsters;

//     constructor() {
//         founders = makeAddr("founders");
//         council = makeAddr("council");

//         frankenpunk = new Token("FrankenPunks", "PUNK");
//         frankenmonsters = new Token("FrankenMonsters", "MNSTR");

//         governance = new Governance();

//         executor = new Executor(address(governance));

//         staking = new Staking(
//             address(frankenpunk), //address _frankenpunks, 
//             address(new Token("FrankenMonsters", "MNSTR")), //address _frankenmonsters,
//             address(governance), //address _governance, 
//             address(executor), //address _executor, 
//             founders, //address _founders,
//             council, //address _council,
//             30 days, //uint _maxStakeBonusTime, 
//             10, //uint _maxStakeBonusAmount,
//             1, //uint _votesMultiplier, 
//             1, //uint _proposalsMultiplier, 
//             1 //uint _executedMultiplier
//         );

//         emit log_uint(7 days);

//         governance.initialize(
//             address(staking), //address _staking,
//             payable(address(executor)), //address payable _executor,
//             founders, //address _founders,
//             council, //address _council,
//             7 days,//uint256 _votingPeriod,
//             1 days, //uint256 _votingDelay,
//             200, //uint256 _proposalThresholdBPS,
//             2_000 //uint256 _quorumVotesBPS
//         );
//     }
// }

