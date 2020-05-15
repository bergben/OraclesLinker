pragma solidity >=0.5.17;

import "./Whitelisted.sol";


/**
 * @title OraclesStore is a contract which stores, updates and provides Chainlink Oracles
 */
contract OraclesStore is ProposalsAggregator {
    struct Job {
        bytes32 id;
        uint256 cost;
    }

    address[] noviceOracles;
    address[] matureOracles;
    address[] seniorOracles;

    // mapping jobType => oracleAddresses
    mapping(bytes32 => address[]) public noviceOraclesPerJobType;
    mapping(bytes32 => address[]) public matureOraclesPerJobType;
    mapping(bytes32 => address[]) public seniorOraclesPerJobType;

    // mapping job to Oracle address and Job Type
    // oracleAddress => jobType => Job
    // allows for usage like jobToOracleAndJobType[oracleAddress]["HttpGetInt256"]
    mapping(address => mapping(bytes32 => Job)) public jobToOracleAndJobType;

    bytes32[] private jobTypes;
    event JobTypeAdded(bytes32);

    function addJobType(bytes32 jobType) external onlyOwner {
        jobTypes[jobType] = jobTypes.push(jobType);
        emit JobTypeAdded(bytes32);
    }

    function addJobToOracle(
        address _oracleAddress,
        bytes32 _id,
        bytes32 _jobType,
        uint256 _cost
    ) private {
        // requirement only valid job types
        // requirement oracleAddress must exist not at proposal though.
    }

    function removeJobFromOracle(address _oracleAddress, bytes32 _id) private {
        // requirement only valid job types
        // requirement oracleAddress must exist
        // requirement jobId must exist
    }

    // also hosts the random value used for retrieval
    // once all nodes have sent task finished event
    // the things where the proposes matches are written on chain, other things are discarded
    // after a max time of 5 minutes, meaning one node failed to send data alltogether or partially or the task finished event
    // the external adapters triggers a send for a forceEndRoundRequest Event
    // which then again goes through the proposed and looks if at least part of the changes have been reported by both nodes and can be added
}
