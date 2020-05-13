pragma solidity >=0.5.17;


/**
 * @title OraclesStore is a contract which stores, updates and provides Chainlink Oracles
 */
contract OraclesStore {
    enum OracleLevel {Novice, Mature, Senior}

    struct OracleNode {
        address oracleNodeAddress;
        OracleLevel level;
    }
}
