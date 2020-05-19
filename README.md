# OraclesLink

Oracles Link provides an easy way to send out Chainlink requests for multiple sources to multiple Chainlink oracles selected at random.

An example run log output can be seen in [example run log file](example%20run.log).

## Architecture
See [Architecture.md](./Architecture.md)

## Usage
An example usage of the package is shown in the SampleContract.sol under OraclesLinker/contracts.

## Development

### Prerequisites
 - [Ganache](https://www.trufflesuite.com/ganache)
 - npm / node.js
 
### 1. Deploy OraclesLinkProvider (with seeding)
 - Run Ganache (create a new workspace and link the truffle.config.js files of the projects in this repo)
 - cd into ./OraclesLinkProvider
 - `npm run init`
 - copy the address of the deployed RandomOraclesProvider Smart contract

### 2. Deploy OraclesLinker (with example Smart Contract)
 - paste the previously copied RandomOraclesProvider address into the file ./OraclesLinker/migrations/2_deploy_contracts.js (line 5)
 - remove line 21: `"oracles-link-provider": "~0.0.1"` from ./OraclesLinker/package.json
 - cd into ./OraclesLinker
 - `npm i`
 - add line 21: `"oracles-link-provider": "~0.0.1"` to ./OraclesLinker/package.json
 - `npm run link` (currently necessary until oracles-link-provider is available through npm)
 - `npm run deploy-and-trigger`
 - oraclesLink request is automatically triggered

### Debugging
Transactions can be debugged with `truffle debug <transactionHash>`


## Limitations
- Freeloading might be a problem: as discussed in [the Chainlink Whitepaper (p.13)](https://link.smartcontract.com/whitepaper) chainlink is also trying to solve this problem
- Cost
  - Put more logic off-chain -> also chainlink is pursuing this goal
  - Add api aggregator job for off-chain aggregation, if the job is supported by more oracles: https://market.link/adapters/86a77a77-cb42-45cd-9afb-75d59195d7ddO
  - optimize code