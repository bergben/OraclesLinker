pragma solidity >=0.5.17;


/**
 * @title OraclesStore is a contract which stores, updates and provides Chainlink Oracles
 */
contract OraclesStore {
    enum OracleLevel {Novice, Mature, Senior}
    enum JobReadableId {HttpGetBytes32, HttpGetUint256, HttpGetBool, HttpGetInt256, HttpPostBytes32}
    // gotta define defaults from Job Specs
    //

    struct Job {
        JobReadableId readableId;
        bytes32 id;
    }

    struct OracleNode {
        address oracleNodeAddress;
        OracleLevel level;
        Job[] jobs;
    }
}
