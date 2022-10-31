# FrankenDAO Contest Details

[Sherlock team will fill this in.]

# Resources

- Docs
- Contracts
- Contract Overview

# Audit Scope

The following contracts are in scope:
- `src/Executor.sol` (x nSLOC)
- `src/Governance.sol` (x nSLOC)
- `src/Staking.sol` (x nSLOC)
- `src/proxy/GovernanceProxy.sol` (x nSLOC)
- `src/utils/Admin.sol` (x nSLOC)
- `src/utils/Refundable.sol` (x nSLOC)

# About

We're a community-based collectibles project featuring art by 3D Punks. 3D FrankenPunks come in an evil array of shapes, traits, and sizes with a few surprises along the way. The collection size is 10,000. Each FrankenPunk allows its owner to vote on creating experiences and influencing project developments which are paid for by the Punksville Community Treasury.

# Testing Setup

FrankenDAO runs on [Foundry](https://book.getfoundry.sh/). 

If you don't have Foundry installed, follow the instructions in their [getting started tutorial](https://book.getfoundry.sh/getting-started/installation)...

To install Foundry (assuming a Linux or macOS System):

`curl -L https://foundry.paradigm.xyz | bash`

This will download foundryup. To start Foundry, run:

`foundryup`

To install dependencies:

`forge install`

To run tests:

`forge test`

The following modifiers are also available:

```
Level 2 (-vv): Logs emitted during tests are also displayed.
Level 3 (-vvv): Stack traces for failing tests are also displayed.
Level 4 (-vvvv): Stack traces for all tests are displayed, and setup traces for failing tests are displayed.
Level 5 (-vvvvv): Stack traces and setup traces are always displayed.
```