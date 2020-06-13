# OraclesLink

Oracles Link provides an easy way to send out Chainlink requests for multiple sources to multiple Chainlink oracles selected at random.

An example run log output can be seen in [example run log file](example%20run.log).

## Showcase / deployed smart contracts

- FrostInsuranceSampleContract:
  - [Etherscan](https://ropsten.etherscan.io/address/0x4ca55A262B7546D90dfF3B194513Edd51862620E)
  - [Chainlink Explorer](https://ropsten.explorer.chain.link/job-runs?search=0x4ca55A262B7546D90dfF3B194513Edd51862620E)
- RandomOraclesProvider:
  - [Etherscan](https://ropsten.etherscan.io/address/0x7D8094e6643D4C3E169fD9426AC4c8Cf83042613)
- OraclesStore:
  - [Etherscan](https://ropsten.etherscan.io/address/0x82E95FFE665D823328251cF644Fef73E7496735f)
- Frost insurance showcase fontend app: 
  - [dApp on IPFS](https://ipfs.io/ipfs/QmPB8AAzuVoZsN4hrakHJvt4gMZVgapFSArtrE6U6SH7NP)
  - [GitHub Pages](https://bergben.github.io/OraclesLinker/)

## Architecture
See [Architecture.md](./Architecture.md)

## Usage
An example usage of the package is shown in the FrostInsuranceSampleContract.sol under OraclesLinker/contracts.

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
 - cd into ./OraclesLinker
 - `npm run init`
 - oraclesLink request is automatically triggered

### Debugging
Transactions can be debugged with `truffle debug <transactionHash>`

### Deploying to ropsten
Run
```truffle migrate --reset --compile-all --network ropsten```

Notes: 
- You may want to run the seeding after deploying: `truffle exec ./dev/truffle-scripts/truffleSeed.js --network ropsten`
- Do not forget to set the correct address for the RandomOraclesProvider contract in ./OraclesLinker/migrations/2_deploy_contracts.js
- Contracts can be verified on etherscan using truffle-flattener

### Testing / Interacting

The default Job type is "HttpGetInt256", the bytes32 value for that string is: 0x48747470476574496e7432353600000000000000000000000000000000000000

## Limitations
- Freeloading might be a problem: as discussed in [the Chainlink Whitepaper (p.13)](https://link.smartcontract.com/whitepaper) chainlink is also trying to solve this problem
- Cost
  - Put more logic off-chain -> also chainlink is pursuing this goal
  - Add api aggregator job for off-chain aggregation, if the job is supported by more oracles: https://market.link/adapters/86a77a77-cb42-45cd-9afb-75d59195d7ddO
  - optimize code