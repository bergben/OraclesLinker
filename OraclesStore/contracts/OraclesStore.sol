pragma solidity >=0.5.17;

import "./WhitelistedProposalsAggregator.sol";
import "./RandomOraclesSelector.sol";


/**
 * @title OraclesStore is a contract which stores, updates and provides Chainlink Oracles
 */
contract OraclesStore is WhitelistedProposalsAggregator, RandomOraclesSelector {
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

    /**
     * overrides method triggered from child contract on round end after proposals clean up
     */
    function onProposalsAggregated() internal {
        for (uint256 i = 0; i < approvedProposals.length; i++) {
            bytes32 key = approvedProposals[i];
            if (proposalOperations[key] == ProposalOperation.AddOracle) {
                addOracle(addOracleProposals[key]);
            }
            if (proposalOperations[key] == ProposalOperation.RemoveOracle) {
                removeOracle(removeOracleProposals[key]);
            }
            if (proposalOperations[key] == ProposalOperation.AddJob) {
                addJob(addJobProposals[key]);
            }
            if (proposalOperations[key] == ProposalOperation.RemoveJob) {
                removeJob(removeJobProposals[key]);
            }
        }
    }

    function addOracle(AddOracleProposal _addOracleProposal) private {}

    function removeOracle(address _oracleAddress) private {}

    function addJob(AddJobProposal _addJobProposal) private {
        // requirement only valid job types
        // requirement oracleAddress must exist not at proposal though.
    }

    function removeJob(RemoveJobProposal _removeJobProposal) private {
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
