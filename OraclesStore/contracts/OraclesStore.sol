pragma solidity 0.6.8;
/** SPDX-License-Identifier: MIT*/

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

    event JobTypeAdded(bytes32);

    // todo add events

    // mapping oracle to uint256 index used for random selection
    mapping(address => uint256) internal oracleToIndex;

    // mapping uint256 index and oracle Level and job type to Oracle
    // used for random oracle selection
    mapping(uint256 => mapping(uint8 => mapping(bytes32 => address))) internal indexAndLevelAndJobTypeToOracle;

    // mapping oracleAddress => level
    mapping(address => OracleLevel) private oracleToLevel;

    // mapping job (jobId) => jobType
    mapping(bytes32 => bytes32) private jobToJobType;

    // mapping to check if jobType already exists
    mapping(bytes32 => bool) private jobTypeExists;

    // mapping to check if oracle already exists
    mapping(address => bool) private oracleExists;

    // mapping to check if job already exists
    mapping(bytes32 => bool) private jobExists;

    // mapping job to Oracle address and Job Type
    // oracleAddress => jobType => Job
    // allows for usage like oracleAndJobTypeToJob[oracleAddress]["HttpGetInt256"]
    mapping(address => mapping(bytes32 => Job)) internal oracleAndJobTypeToJob;

    mapping(uint8 => mapping(bytes32 => uint256)) internal levelAndJobTypeToCount;

    function addJobType(bytes32 jobType) external onlyOwner() {
        require(!jobTypeExists[jobType], "Job type already exists");
        jobTypeExists[jobType] = true;
        emit JobTypeAdded(jobType);
    }

    function onProposalsAggregated() internal override {
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

    function removeOracle(address _oracleAddress) private isOracleExists(_oracleAddress) {
        // remove all assigned jobs
        // delete indexToOracle[oracleToIndex[_oracleAddress]];
        // delete oracleToIndex[_oracleAddress];

        delete oracleExists[_oracleAddress];
        delete oracleToLevel[_oracleAddress];
    }

    function addOracle(AddOracleProposal storage _addOracleProposal) private isOracleNotExists(_addOracleProposal.oracleAddress) {
        address oracleAddress = _addOracleProposal.oracleAddress;

        require(_addOracleProposal.level >= 0 && _addOracleProposal.level <= 2, "Invalid oracle level");
        OracleLevel oracleLevel = castUint8LevelToEnum(_addOracleProposal.level);

        oracleToLevel[oracleAddress] = oracleLevel;
        oracleExists[oracleAddress] = true;

        // todo add oracleToIndex
        // todo add indexToOracle
        // todo can I even pick a random oracle like this? I need index per jobTypeAndOracle....
    }

    function removeJob(RemoveJobProposal storage _removeJobProposal) private isJobExists(_removeJobProposal.id) {
        address oracleAddress = _removeJobProposal.oracleAddress;
        bytes32 jobType = jobToJobType[_removeJobProposal.id];
        OracleLevel oracleLevel = oracleToLevel[oracleAddress];
        bytes32 jobId = _removeJobProposal.id;

        delete oracleAndJobTypeToJob[oracleAddress][jobType];
        levelAndJobTypeToCount[castLevelEnumToUint8(oracleLevel)][jobType]--;
        delete jobToJobType[jobId];
        delete jobExists[jobId];
    }

    function addJob(AddJobProposal storage _addJobProposal)
        private
        isJobTypeExists(_addJobProposal.jobType)
        isOracleExists(_addJobProposal.oracleAddress)
        isJobNotExists(_addJobProposal.id)
    {
        address oracleAddress = _addJobProposal.oracleAddress;
        bytes32 jobType = _addJobProposal.jobType;
        OracleLevel oracleLevel = oracleToLevel[oracleAddress];
        bytes32 jobId = _addJobProposal.id;

        jobToJobType[jobId] = jobType;
        oracleAndJobTypeToJob[oracleAddress][jobType] = Job(jobId, _addJobProposal.cost);
        levelAndJobTypeToCount[castLevelEnumToUint8(oracleLevel)][jobType]++;
        jobExists[jobId] = true;
    }

    function castLevelEnumToUint8(OracleLevel _level) private pure returns (uint8) {
        if (_level == OracleLevel.Novice) {
            return 0;
        }
        if (_level == OracleLevel.Mature) {
            return 1;
        } else {
            return 2;
        }
    }

    function castUint8LevelToEnum(uint8 _level) private pure returns (OracleLevel) {
        if (_level == 0) {
            return OracleLevel.Novice;
        }
        if (_level == 1) {
            return OracleLevel.Mature;
        } else {
            return OracleLevel.Senior;
        }
    }

    modifier isJobExists(bytes32 _id) {
        require(jobExists[_id], "Job does not exist");
        _;
    }

    modifier isJobNotExists(bytes32 _id) {
        require(!jobExists[_id], "Job already exists");
        _;
    }

    modifier isOracleExists(address _oracleAddress) {
        require(oracleExists[_oracleAddress], "Oracle does not exist");
        _;
    }

    modifier isOracleNotExists(address _oracleAddress) {
        require(!oracleExists[_oracleAddress], "Oracle already exists");
        _;
    }

    modifier isJobTypeExists(bytes32 _jobType) {
        require(jobTypeExists[_jobType], "Job Type does not exist");
        _;
    }
}
