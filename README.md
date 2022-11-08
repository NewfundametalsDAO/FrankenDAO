# FrankenDAO Contest Details

- 16,000 USDC main award pot
- Join [Sherlock Discord](https://discord.gg/MABEWyASkp)
- Submit findings using the issue page in your private contest repo (label issues as med or high)
- [Read for more details](https://docs.sherlock.xyz/audits/watsons)
- Starts November 9, 2022 15:00 UTC
- Ends November 14, 2022 15:00 UTC

# Resources

- [Website](https://www.3dfrankenpunks.com/)
- [Twitter](https://twitter.com/3dFrankenPunks)
- [Docs](https://docs.3dfrankenpunks.com/)
- [GitHub](https://github.com/NewfundametalsDAO)

# On-chain context

```
DEPLOYMENT: [e.g. mainnet, arbitrum, optimism, ..]
ERC20: [e.g. any, none, USDC, USDC and USDT]
ERC721: [e.g. any, none, UNI-V3]
```

# Audit Scope

The following contracts are in scope:

- `src/Governance.sol` (337 nSLOC)
- `src/Staking.sol` (333 nSLOC)
- `src/Executor.sol` (44 nSLOC)
- `src/proxy/GovernanceProxy.sol` (27 nSLOC)
- `src/utils/Admin.sol` (56 nSLOC)
- `src/utils/Refundable.sol` (22 nSLOC)

# About

We're a community-based collectibles project featuring art by 3D Punks. 3D FrankenPunks come in an evil array of shapes, traits, and sizes with a few surprises along the way. The collection size is 10,000. Each FrankenPunk allows its owner to vote on creating experiences and influencing project developments which are paid for by the Punksville Community Treasury.

# Testing Setup

FrankenDAO runs on [Foundry](https://book.getfoundry.sh/).

- To download foundryup (assuming Linux or macOS): `curl -L https://foundry.paradigm.xyz | bash`
- To start Foundry, run: `foundryup`
- To install dependencies: `forge install`

Because our contracts interact with the live Frankenpunks and Frankenmonsters contracts, all tests require forking Ethereum mainnet. We have the `foundry.toml` file set up to fork mainnet and set the gas price to 25 gwei, but you'll need to add your own RPC URL for it to work.

Create a `.env` file at the root of the folder and add the following:

```
MAINNET_RPC_URL=http://INSERT_YOUR_URL_HERE.com
```

Source the environment variable by running the following in your terminal: `source .env`

You are then ready to run tests:

```solidity
forge test -vvv // only show traces for failing tests
forge test -vvvv // show traces for all tests
forge test -vvv --match testName // only run tests that match testName
```

See the [Foundry Book](https://book.getfoundry.sh/) for more on Foundry.
