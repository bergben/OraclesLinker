pragma solidity 0.6.8;
/** SPDX-License-Identifier: MIT*/

import "./WhitelistedProposalsAggregator.sol";


/**
 * @title OraclesStore is a contract which stores, updates and provides Chainlink Oracles
 */
contract OraclesStore is WhitelistedProposalsAggregator {
    enum OracleLevel {Novice, Mature, Senior}
    struct Job {
        bytes32 id;
        uint256 cost;
    }

    // todo add events
    event JobTypeAdded(bytes32);

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

    // mapping hash or oracle and jobId to index in the array of the mapping oracleToJobIds
    mapping(bytes32 => uint256) private oracleAndJobIdToIndex;

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
        resetProposalsRound();
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

    function removeOracle(address _oracleAddress) private {
        require(oracleExists[_oracleAddress], "Oracle does not exist");

        // remove all assigned jobs
        bytes32[] storage assignedJobIds = oracleToJobIds[_oracleAddress];
        for (uint256 i = 0; i < assignedJobIds.length; i++) {
            removeJob(_oracleAddress, assignedJobIds[i]);
        }

        delete oracleExists[_oracleAddress];
        delete oracleToLevel[_oracleAddress];
    }

    function addOracle(AddOracleProposal storage _addOracleProposal) private {
        require(!oracleExists[_addOracleProposal.oracleAddress], "Oracle already exists");

        address oracleAddress = _addOracleProposal.oracleAddress;

        require(_addOracleProposal.level >= 0 && _addOracleProposal.level <= 2, "Invalid oracle level");
        OracleLevel oracleLevel = castUint8LevelToEnum(_addOracleProposal.level);

        oracleToLevel[oracleAddress] = oracleLevel;
        oracleExists[oracleAddress] = true;
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
    }

    function addJob(AddJobProposal storage _addJobProposal) private {
        require(!jobExists[_addJobProposal.id], "Job already exists");
        require(jobTypeExists[_addJobProposal.jobType], "Job Type does not exist");
        require(oracleExists[_addJobProposal.oracleAddress], "Oracle does not exist");

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
}
