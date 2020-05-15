pragma solidity >=0.5.17;


/**
 * @title Library for common OraclesLink structs etc.
 */
library OraclesLink {
    enum AggregationMethod {Median, None}

    struct Requirements {
        uint256 noviceOraclesCount;
        uint256 noviceMinResponses;
        uint256 matureOraclesCount;
        uint256 matureMinResponses;
        uint256 seniorOraclesCount;
        uint256 seniorMinResponses;
    }
}
