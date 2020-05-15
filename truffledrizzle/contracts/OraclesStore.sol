pragma solidity >=0.5.17;

import "./OraclesLink.sol";


/**
 * @title OraclesStore is a contract which stores, updates and provides Chainlink Oracles
 */
contract OraclesStore {
    // also hosts the random value used for retrieval
    // stores a list of oracles per jobType
    // gotta define defaults from Job Specs -> is done on External Adapter
    // external adapter link https://market.link/v1/search/nodes?sortOrder=desc&verified=true&networkId=3&size=1000
    // make sure to set correct networkId on deployment, Ropsten is networkId 3, Mainnet is 1
    /**
     */
    // nodes using the EA can propose changes through several calls
    // adding oracle
    // removing oracle
    // updating oracle
    // once both (all) nodes have sent task finished event
    // the things where the proposes matches are written on chain, other things are discarded
    // after a max time of 5 minutes, meaning one node failed to send data alltogether or partially or the task finished event
    // the external adapters triggers a send for a forceEndRoundRequest Event
    // which then again goes through the proposed and looks if at least part of the changes have been reported by both nodes and can be added
}
