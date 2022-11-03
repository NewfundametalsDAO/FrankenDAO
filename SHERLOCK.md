# FrankenDAO Contest Details

[Sherlock team will fill this in.]

# Resources

- Docs
- Contracts
- Contract Overview

# Audit Scope

The following contracts are in scope:
- `src/Governance.sol` (331 nSLOC)
- `src/Staking.sol` (325 nSLOC)
- `src/Executor.sol` (44 nSLOC)
- `src/proxy/GovernanceProxy.sol` (27 nSLOC)
- `src/utils/Admin.sol` (56 nSLOC)
- `src/utils/Refundable.sol` (22 nSLOC)

# About

We're a community-based collectibles project featuring art by 3D Punks. 3D FrankenPunks come in an evil array of shapes, traits, and sizes with a few surprises along the way. The collection size is 10,000. Each FrankenPunk allows its owner to vote on creating experiences and influencing project developments which are paid for by the Punksville Community Treasury.

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
mainnet = "http://INSERT_YOUR_RPC_ENDPOINT_HERE.com"
```

To run tests:

`forge test`

See the [Foundry Book](https://book.getfoundry.sh/) for more on Foundry.