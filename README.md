# OraclesLink

Oracles Link provides an easy way to send out Chainlink requests for multiple sources to multiple Chainlink oracles selected at random.

## Architecture
See [Architecture.md](./Architecture.md)

## Usage
An example usage of the package is shown in the SampleContract.sol under OraclesLinker/contracts.

## Development

### Prerequisites
 - [Ganache](https://www.trufflesuite.com/ganache)
 - npm / node.js
 
### 1. Deploy OraclesLinkProvider (with seeding)
 - Run Ganache
 - `cd ./OraclesLinkProvider && npm run init`
 - copy the address of the deployed RandomOraclesProvider Smart contract

### 2. Deploy OraclesLinker (with example Smart Contract)
 - paste the previously copied RandomOraclesProvider address into the file ./OraclesLinker/migrations/2_deploy_contracts.js (line 5);
 - cd into ./OraclesLinker
 - `npm run init`
 - oraclesLink request is automatically triggered


## Limitations
- Freeloading as discussed in Chainlink Whitepaper, chainlink is also trying to solve this problem
- Cost
  - Put more stuff off-chain -> also chainlink is pursuing this goal
  - Add api aggregator job for off-chain aggregation, if the job is supported by more oracles: https://market.link/adapters/86a77a77-cb42-45cd-9afb-75d59195d7ddO
  - optimize code