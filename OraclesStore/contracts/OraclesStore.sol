pragma solidity >=0.5.17;

import "./WhitelistedProposalsAggregator.sol";
import "./RandomOraclesSelector.sol";


/**
 * @title OraclesStore is a contract which stores, updates and provides Chainlink Oracles
 */
contract OraclesStore is WhitelistedProposalsAggregator, RandomOraclesSelector {
    enum OracleLevel {Novice, Mature, Senior}
    struct Job {
        bytes32 id;
        uint256 cost;
    }

    address[] private noviceOracles;
    address[] private matureOracles;
    address[] private seniorOracles;

    bytes32[] private jobTypes;

    event JobTypeAdded(bytes32);

    // todo add access lecels
    // todo add modifiers and requirements
    // todo add events

    // mapping jobType => oracleAddresses
    mapping(bytes32 => address[]) internal noviceOraclesPerJobType;
    mapping(bytes32 => address[]) internal matureOraclesPerJobType;
    mapping(bytes32 => address[]) internal seniorOraclesPerJobType;

    // mappings for count for oracles per level
    mapping(uint8 => uint256) internal oraclesCountPerLevel;

    // mapping uint256 to oracle address to identify a randomly selected oracle
    mapping(uint256 => address) internal oraclesIndex;

    // mapping oracleAddress => level
    mapping(address => OracleLevel) private oraclesLevel;

    // mapping to check if jobType already exists
    mapping(bytes32 => bool) private jobTypeExists;

    // mapping to ensure that no oracle exists twice

    // mapping job to Oracle address and Job Type
    // oracleAddress => jobType => Job
    // allows for usage like jobToOracleAndJobType[oracleAddress]["HttpGetInt256"]
    mapping(address => mapping(bytes32 => Job)) internal jobToOracleAndJobType;

    function addJobType(bytes32 jobType) external onlyOwner() {
        require(!jobTypeExists[jobType], "Job type already exists");
        jobTypes.push(jobType);
        emit JobTypeAdded(jobType);
    }

    /**
     * overrides method triggered from child contract on round end after proposals clean up
     */
    function onProposalsAggregated() internal {
        handleApprovedRemoveOracles();
        handleApprovedAddOracles();
        handleApprovedRemoveJobs();
        handleApprovedAddJobs();
    }

    function handleApprovedRemoveOracles() private {
        for (uint256 i = 0; i < approvedRemoveOracleKeys.length; i++) {
            bytes32 key = approvedRemoveOracleKeys[i];
            removeOracle(removeOracleProposals[key]);
        }
    }

    function handleApprovedAddOracles() private {
        for (uint256 i = 0; i < approvedAddOracleKeys.length; i++) {
            bytes32 key = approvedAddOracleKeys[i];
            addOracle(addOracleProposals[key]);
        }
    }

    function handleApprovedRemoveJobs() private {
        for (uint256 i = 0; i < approvedRemoveJobKeys.length; i++) {
            bytes32 key = approvedRemoveJobKeys[i];
            removeJob(removeJobProposals[key]);
        }
    }

    function handleApprovedAddJobs() private {
        for (uint256 i = 0; i < approvedAddJobKeys.length; i++) {
            bytes32 key = approvedAddJobKeys[i];
            addJob(addJobProposals[key]);
        }
    }

    function removeOracle(address _oracleAddress) private {
        if (oraclesLevel[_oracleAddress] == OracleLevel.Novice) {
            oraclesCountPerLevel[uint8(OracleLevel.Novice)]--;
        }
        if (oraclesLevel[_oracleAddress] == OracleLevel.Mature) {
            oraclesCountPerLevel[uint8(OracleLevel.Mature)]--;
        }
        if (oraclesLevel[_oracleAddress] == OracleLevel.Senior) {
            oraclesCountPerLevel[uint8(OracleLevel.Senior)]--;
        }
    }

    function addOracle(AddOracleProposal storage _addOracleProposal) private {
        if (_addOracleProposal.level == 0) {
            noviceOracles.push(_addOracleProposal.oracleAddress);
            oraclesCountPerLevel[uint8(OracleLevel.Novice)]++;
            oraclesLevel[_addOracleProposal.oracleAddress] = OracleLevel.Novice;
        }
        if (_addOracleProposal.level == 1) {
            matureOracles.push(_addOracleProposal.oracleAddress);
            oraclesCountPerLevel[uint8(OracleLevel.Mature)]++;
            oraclesLevel[_addOracleProposal.oracleAddress] = OracleLevel.Mature;
        }
        if (_addOracleProposal.level == 2) {
            seniorOracles.push(_addOracleProposal.oracleAddress);
            oraclesCountPerLevel[uint8(OracleLevel.Senior)]++;
            oraclesLevel[_addOracleProposal.oracleAddress] = OracleLevel.Senior;
        }
    }

    function removeJob(RemoveJobProposal storage _removeJobProposal) private {
        // requirement only valid job types
        // requirement oracleAddress must exist
        // requirement jobId must exist
    }

    function addJob(AddJobProposal storage _addJobProposal) private {
        // requirement only valid job types
        // requirement oracleAddress must exist
    }

    modifier jobExists() {
        _;
    }

    modifier jobNotExists() {
        _;
    }

    modifier oracleExists() {
        _;
    }

    modifier oracleNotExists() {
        _;
    }

    modifier validJobType() {
        _;
    }
}
