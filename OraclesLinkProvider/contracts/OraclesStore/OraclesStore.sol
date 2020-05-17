pragma solidity 0.6.8;
/** SPDX-License-Identifier: MIT*/

import "./WhitelistedProposalsAggregator.sol";
import "./OraclesProviderInterface.sol";


/**
 * @title OraclesStore is a contract which stores, updates and provides Chainlink Oracles
 */
contract OraclesStore is WhitelistedProposalsAggregator, OraclesProviderInterface {
    struct Job {
        bytes32 id;
        uint256 cost;
    }

    event JobTypeAdded(bytes32 jobType);
    event OracleAdded(address oracleAddress);
    event OracleRemoved(address oracleAddress);
    event JobAdded(address oracleAddress, bytes32 jobId, bytes32 jobType, uint256 cost);
    event JobRemoved(address oracleAddress, bytes32 jobId);
    event RoundHandled(uint256 roundStartTimestamp);

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

    // mapping to check if job type already exists for a certain oracle
    mapping(address => mapping(bytes32 => bool)) private oracleJobTypeExists;

    // mapping oracle and jobType to Job
    mapping(address => mapping(bytes32 => Job)) private oracleAndJobTypeToJob;

    // mapping Oracle Level and Job Type to available Oracles
    mapping(uint8 => mapping(bytes32 => address[])) private levelAndJobTypeToOracles;

    // mapping hash of oracle level, job type and oracle address to the index in the array of the mapping levelAndJobTypeToOracles
    mapping(bytes32 => uint256) private levelAndJobTypeAndOracleToIndex;

    // mapping oracle => all assigned jobIds
    mapping(address => bytes32[]) private oracleToJobIds;

    // mapping hash of oracle and jobId to index in the array of the mapping oracleToJobIds
    mapping(bytes32 => uint256) private oracleAndJobIdToIndex;

    function oraclesCount(uint8 _level, bytes32 _jobType)
        external
        override
        view
        isJobTypeExists(_jobType)
        isOracleLevelExists(_level)
        returns (uint256 count)
    {
        return levelAndJobTypeToOracles[_level][_jobType].length;
    }

    function oracleAtIndex(
        uint8 _level,
        bytes32 _jobType,
        uint256 _index
    )
        external
        override
        view
        isJobTypeExists(_jobType)
        isOracleLevelExists(_level)
        returns (
            address oracleAddress,
            bytes32 id,
            uint256 cost
        )
    {
        address[] storage oracles = levelAndJobTypeToOracles[_level][_jobType];
        require(_index >= 0 && _index < oracles.length, "Index out of bounds");
        Job storage job = oracleAndJobTypeToJob[oracles[_index]][_jobType];
        return (oracles[_index], job.id, job.cost);
    }

    function addJobType(bytes32 _jobType) external onlyOwner() {
        require(!jobTypeExists[_jobType], "Job type already exists");
        jobTypeExists[_jobType] = true;
        emit JobTypeAdded(_jobType);
    }

    function onProposalsAggregated() internal override {
        handleApprovedRemoveOracles();
        handleApprovedAddOracles();
        handleApprovedRemoveJobs();
        handleApprovedAddJobs();
        resetProposalsRound();
        emit RoundHandled(lastRoundStartTimestamp);
    }

    function handleApprovedRemoveOracles() private {
        for (uint256 i = 0; i < approvedRemoveOracleKeys.length; i++) {
            bytes32 key = approvedRemoveOracleKeys[i];
            removeOracle(removeOracleProposals[key]);
            removeProposalMappings(key);
        }
    }

    function handleApprovedAddOracles() private {
        for (uint256 i = 0; i < approvedAddOracleKeys.length; i++) {
            bytes32 key = approvedAddOracleKeys[i];
            addOracle(addOracleProposals[key]);
            removeProposalMappings(key);
        }
    }

    function handleApprovedRemoveJobs() private {
        for (uint256 i = 0; i < approvedRemoveJobKeys.length; i++) {
            bytes32 key = approvedRemoveJobKeys[i];
            removeJob(removeJobProposals[key].oracleAddress, removeJobProposals[key].id);
            removeProposalMappings(key);
        }
    }

    function handleApprovedAddJobs() private {
        for (uint256 i = 0; i < approvedAddJobKeys.length; i++) {
            bytes32 key = approvedAddJobKeys[i];
            addJob(addJobProposals[key]);
            removeProposalMappings(key);
        }
    }

    function removeOracle(address _oracleAddress) private isOracleExists(_oracleAddress) {
        // remove all assigned jobs
        bytes32[] storage assignedJobIds = oracleToJobIds[_oracleAddress];
        for (uint256 i = 0; i < assignedJobIds.length; i++) {
            removeJob(_oracleAddress, assignedJobIds[i]);
        }

        delete oracleExists[_oracleAddress];
        delete oracleToLevel[_oracleAddress];

        emit OracleRemoved(_oracleAddress);
    }

    function addOracle(AddOracleProposal storage _addOracleProposal) private isOracleLevelExists(_addOracleProposal.level) {
        require(!oracleExists[_addOracleProposal.oracleAddress], "Oracle already exists");

        address oracleAddress = _addOracleProposal.oracleAddress;

        OracleLevel oracleLevel = castUint8LevelToEnum(_addOracleProposal.level);

        oracleToLevel[oracleAddress] = oracleLevel;
        oracleExists[oracleAddress] = true;

        emit OracleAdded(oracleAddress);
    }

    function removeJob(address _oracleAddress, bytes32 _id) private {
        require(jobExists[_id], "Job does not exist");

        bytes32 jobType = jobToJobType[_id];
        OracleLevel oracleLevel = oracleToLevel[_oracleAddress];

        delete oracleJobTypeExists[_oracleAddress][jobType];
        delete oracleAndJobTypeToJob[_oracleAddress][jobType];
        delete jobToJobType[_id];

        /**
         * For removing the correct element in the array of levelAndJobTypeToOracles[castLevelEnumToUint8(oracleLevel)][jobType]
         * Remove element from array without preserving the same order
         * this is okay because this array is anyway only used for random oracle retrival
         * so, it's actually a feature ;)
         */
        bytes32 oracleIndexKey = keccak256(abi.encode(oracleLevel, jobType, _oracleAddress));
        uint256 oracleIndex = levelAndJobTypeAndOracleToIndex[oracleIndexKey];
        address[] storage oracles = levelAndJobTypeToOracles[castLevelEnumToUint8(oracleLevel)][jobType];
        // replace element at index with element from last element in array
        oracles[oracleIndex] = oracles[oracles.length - 1];
        // remove last element of array
        oracles.pop();
        delete oracleIndex;

        // the same is done for the oracleToJobIds mapping, order doesn't matter here either. But it's not a feature anymore :(
        bytes32 jobIdIndexKey = keccak256(abi.encode(_oracleAddress, _id));
        uint256 jobIdIndex = oracleAndJobIdToIndex[jobIdIndexKey];
        bytes32[] storage jobIds = oracleToJobIds[_oracleAddress];
        // replace element at index with element from last element in array
        jobIds[jobIdIndex] = jobIds[jobIds.length - 1];
        // remove last element of array
        jobIds.pop();
        delete jobIdIndex;

        delete jobExists[_id];

        emit JobRemoved(_oracleAddress, _id);
    }

    function addJob(AddJobProposal storage _addJobProposal)
        private
        isJobTypeExists(_addJobProposal.jobType)
        isOracleExists(_addJobProposal.oracleAddress)
    {
        require(!jobExists[_addJobProposal.id], "Job already exists");

        address oracleAddress = _addJobProposal.oracleAddress;
        bytes32 jobType = _addJobProposal.jobType;
        OracleLevel oracleLevel = oracleToLevel[oracleAddress];
        bytes32 jobId = _addJobProposal.id;

        // require job type must only exist once per oracle
        require(!oracleJobTypeExists[oracleAddress][jobType], "Oracle already has a job with this job type");

        oracleJobTypeExists[oracleAddress][jobType] = true;
        jobToJobType[jobId] = jobType;
        oracleAndJobTypeToJob[oracleAddress][jobType] = Job(jobId, _addJobProposal.cost);
        // get key for the levelAndJobTypeAndOracleToIndex
        bytes32 oraclesKey = keccak256(abi.encode(oracleLevel, jobType, oracleAddress));
        address[] storage oracles = levelAndJobTypeToOracles[castLevelEnumToUint8(oracleLevel)][jobType];
        oracles.push(oracleAddress);
        levelAndJobTypeAndOracleToIndex[oraclesKey] = oracles.length - 1;

        // get key for the oracleAndJobIdToIndex
        bytes32 jobIdsKey = keccak256(abi.encode(oracleAddress, jobId));
        bytes32[] storage jobIds = oracleToJobIds[oracleAddress];
        jobIds.push(jobId);
        oracleAndJobIdToIndex[jobIdsKey] = jobIds.length - 1;

        jobExists[jobId] = true;
        emit JobAdded(oracleAddress, jobId, jobType, _addJobProposal.cost);
    }

    function castLevelEnumToUint8(OracleLevel _level) public override pure returns (uint8) {
        if (_level == OracleLevel.Novice) {
            return 0;
        }
        if (_level == OracleLevel.Mature) {
            return 1;
        } else {
            return 2;
        }
    }

    function castUint8LevelToEnum(uint8 _level) public override pure returns (OracleLevel) {
        if (_level == 0) {
            return OracleLevel.Novice;
        }
        if (_level == 1) {
            return OracleLevel.Mature;
        } else {
            return OracleLevel.Senior;
        }
    }

    modifier isOracleLevelExists(uint8 _level) {
        require(_level >= 0 && _level <= 2, "Invalid oracle level");
        _;
    }

    modifier isOracleExists(address _oracleAddress) {
        require(oracleExists[_oracleAddress], "Oracle does not exist");
        _;
    }

    modifier isJobTypeExists(bytes32 _jobType) {
        require(jobTypeExists[_jobType], "Job Type does not exist");
        _;
    }
}
