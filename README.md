# FrankenDAO

## Description

FrankenDAO is the staking and governance component of the FrankenPunks
ecosystem. The DAO will have full control over the FrankenPunks treasury.

The basic user flow for the DAO is as follows:
- Holders of FrankenPunks or FrankenMonsters can stake their NFTs
- They will receive stakedFrankenDAO NFTs in return, which retain their token's ID and characteristics
- Stakers will earn votes based on the length of time they stake, the uniqueness of their NFT, and their involvement in the DAO
- Stakers can use this voting power to propose and vote on proposals
- Alternatively, they can delegate their votes to another user
- Proposals that receive sufficient votes from the community will be permissionalessly executed

The DAO implementation draws heavily from NounsDAO, with deviations described in the contracts.

```
├── Executor.sol
├── Governance.sol
├── Staking.sol
├── errors
│   └── FrankenDAOErrors.sol
├── interfaces
│   ├── IAdmin.sol
│   ├── IERC721.sol
│   ├── IExecutor.sol
│   ├── IGovernance.sol
│   ├── IRefundable.sol
│   └── IStaking.sol
├── proxy
│   └── GovernanceProxy.sol
└── utils
    ├── Admin.sol
    ├── Refundable.sol
    └── SafeCast.sol
```

| Contract | Description | 
| --- | ---  |
| `Staking.sol`  | Contract for staking FrankenPunks and FrankenMonsters, delegating, and calculating voting power  |
| `Governance.sol`  | Creating and voting on proposals or queuing the transactions defined in a passed proposal  |
| `Executor.sol`  | Treasury for holding DAO funds and executing the transactions of approved proposals  |
| `Admin.sol`  | Admin roles and permission checks for contracts. Defines roles for founders, commmunity council, the executor contract, and a pauser. |
| `Refundable.sol`  | Contract for shared functionality for refunding gas on certain methods. Used to refund staking, delegating, creating proposals, and voting  |
| `GovernanceProxy.sol`  | ERC1967 proxy for Governance upgradeability (based on Open Zeppelin's implementation with a few changes)  |

Here is a simplified overview of the major actions user's take in the system:

![FrankenDAO Governance Overview](./assets/frankendao.png)

### Staking

The Staking contract accepts ownership of FrankenPunks and FrankenMonsters and
mints a corresponding staked FrankenPunk or FrankenMonster, which is
non-transferable.

#### Staking and Unstaking Tokens

The Staking contract provides methods for staking and unstaking the two tokens,
FrankenPunks and FrankenMonsters. Staking is allowed unless it is specifically
paused at the contract-level. When users stake their tokens, they commit to
a lock-window, wherein they cannot unstake their tokens in exchange for a voting
power bonus (voting power explained more in-depth below). The lock-window can be
0, in which case the token(s) can be unstaked at any time.

Unstaking is generally allowed unless one of two things is true:

1. The staking window has not elapsed
2. A vote has been cast in a proposal using the voting power tied to a token.

In the first case, there is no way to unstake a token that has been locked up
other than for the stake window to pass.

In the second case, we block unstaking of tokens if the voting power (whether
delegated or not) has been cast in an active proposal. In this case, the token
can be unstaked once the proposal is no longer active (it has failed or
succeeded). Locking tokens (and their votes) during voting is how we were able
to remove the checkpoints feature used in Governor Bravo and NounsDAO.

#### Voting Power

Voting power is determined by three factors:

1. Number and rarity of the tokens you stake
2. Participation in governance through proposing, voting, and executing
3. Delegated voting power

Voting power is split along the two lines of token-based voting power and
community participation-based voting power (your community score):

- Staking a rare token (with a high Evil score) earns you more voting power than staking a common one
- Staking a lot of tokens earns you more voting power
- Creating a proposal that passes a vote increases your voting power

The third source of voting power is that members can elect to delegate their
votes. A member's community score is tied to their address based on their
participation in DAO governance, and is not delegate-able. But token-based
voting power is.

### Governance

The governance system is a hybrid between Compound's Governor Bravo and
NounsDAO. Actions like creating a proposal, casting a vote, and queueing
a passed proposal all occur on Governance.sol, which is behind a proxy
(GovernanceProxy.sol). Transactions in approved proposals are queued to
Executor.sol, where are are subject to a time lock. Just like in Nouns,
thresholds for proposing and reaching quorum are accomplished through
basis-points of the total voting power in the system (token voting power and
community voting power).

We have made a couple of substantive changes to the Nouns and Bravo models.
Namely:

- removed checkpoints of voting power (as in the Comp token)
- track votes, proposals created, and proposal passed by user for community score calculation
- track votes, proposals created, and proposal passed across all users counting towards community voting power
- removed tempProposal from the proposal creation process
- added a verification step for new proposals to confirm they passed Snapshot pre-governance
- adjusted roles and permissions
- added an array to track Active Proposals and a clear() function to remove them 
- removed the ability to pass a reason along with a vote, and to vote by EIP-712 signature

Some other smaller changes we've made:

- Min and Max values for parameters on Governance and Executor are done with timestamps
- add optional gas refunding for voting and creating proposals
- allow the contract to receive Ether (for gas refunds)

#### Executor

The Executor contract is where transactions are locked for a window of time
before they can be executed. Architecturally, this is similar to Nouns and
Bravo. We made the following changes to those systems:

- DELAY and GRACE_PERIOD are hardcoded
- we move admin check logic into a modifier and rename admin to governance
- governance address cannot be changed (in the event of an upgrade, we will first transfer funds to new Executor)
- we don't allow queueing of identical transactions
- we don't check whether transactions are past their grace period because that is checked in Governance

### Utilities

To support the above contracts, we've implemented the following utility contracts:
Proxy, Admin, and Refundable

#### Proxy

This is OpenZeppelin's TransparentUpgrardeableProxy but with a few slight
modifications:

- allows Admin to access the fallback function (so that Executor can call implementation functions)
- changes ifAdmin modifier to onlyAdmin, reverting vs fallback if non admin calls a proxy function
- gives non admin ability to access proxy view functions: admin() and implementation()

#### Admin

This contract is where we manage the four roles shared across our Governance and
Staking and where we implement modifiers for checking those roles. The four
roles are:

1. `founders`, a multi-sig of the project's founders
2. `council`, a multi-sig of appointed community members
3. `executor`, the current implementation of Executor
4. `pauser`, an address with the ability to pause the contract

#### Refundable

This contract is for shared functionality of refunding certain transactions. It
is implemented by Staking and Governance, with the following actions being
refundable:

1. Proposing
2. Voting
3. Staking
4. Delegating

# Testing Setup

FrankenDAO runs on [Foundry](https://book.getfoundry.sh/). 

To install Foundry (assuming a Linux or macOS System):

`curl -L https://foundry.paradigm.xyz | bash`

This will download foundryup. To start Foundry, run:

`foundryup`

To install dependencies:

`forge install`

Because our contracts interact with the live Frankenpunks and Frankenmonsters contracts, all tests require forking Ethereum mainnet.

To add your RPC_URL for mainnet forking, open `foundry.toml` and add the following:

```
[rpc_endpoints]
mainnet = "https://mainnet.infura.io/v3/324422b5714843da8a919967a9c652ac"
```

To run tests:

`forge test`

See the [Foundry Book](https://book.getfoundry.sh/) for more on Foundry.
