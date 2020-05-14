pragma solidity >=0.5.17;


/**
 * @title Library for common OraclesLink structs etc.
 */
library OraclesLink {
    enum OracleLevel {Novice, Mature, Senior}
    enum JobType {HttpGetInt256} // others would be HttpGetBytes32, HttpGetUint256, HttpGetBool, HttpPostBytes32
    enum AggregationMethod {Median, None}

    struct Requirements {
        uint256 noviceOraclesCount;
        uint256 noviceMinResponses;
        uint256 matureOraclesCount;
        uint256 matureMinResponses;
        uint256 seniorOraclesCount;
        uint256 seniorMinResponses;
    }

    struct Job {
        bytes32 id;
        JobType jobType;
        uint256 payment;
    }

    struct StoredOracle {
        address oracleAddress;
        OracleLevel level;
        Job[] jobs;
    }
}
