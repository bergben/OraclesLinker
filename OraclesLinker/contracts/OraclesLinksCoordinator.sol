pragma solidity 0.6.8;

// libraries
import "./OraclesLink.sol";
import "./OraclesLinkInt256.sol";
import "@chainlink/contracts/src/v0.6/Median.sol";

// contracts
import "./RandomOraclesProviderHost.sol";
import "./OraclesChainlinkHandler.sol";


/** SPDX-License-Identifier: MIT*/

/**
 * @title OraclesLinksCoordinator is a contract which manages OraclesLinks
 */
abstract contract OraclesLinksCoordinator is RandomOraclesProviderHost, OraclesChainlinkHandlerMock {
    enum OracleLevel {Novice, Mature, Senior}

    event OraclesLinkRequested(bytes32 indexed id);
    event OraclesLinkFulfilled(bytes32 indexed id);
    event OraclesLinkChainlinkSourceCreated(bytes32 chainlinkRequestId, bytes32 sourceResponsesId, string url);
    event OraclesLinkSourceComplete(bytes32 oraclesLinkId, bytes32 sourceResponsesId);
    event OraclesLinkAggregated(bytes32 oraclesLinkId, int256 result);
    event OraclesLinkSourceAggregated(bytes32 oraclesLinkId, bytes32 sourceResponsesId, int256 result);
    event ChainlinkAnswerInt256Handled(bytes32 chainlinkRequestId, bytes32 sourceResponsesId, bytes32 oraclesLinkId, int256 answer);

    /**
     * @notice The fulfill method for the calling smart contract that overrides it as callback
     * @param _oraclesLinkId The ID that was generated for the OraclesLink
     * @param _answer The answer provided by the Oracles
     */
    function fulfillOraclesLinkInt256(bytes32 _oraclesLinkId, int256 _answer) internal virtual;

    uint8 private constant MAX_ORACLES_PER_LEVEL = 21;
    uint256 private oracleLinksCount = 1;

    struct ResponseInt256 {
        int256 answer;
        OracleLevel oracleLevel;
    }

    struct OraclesLinkRequest {
        bool exists;
        uint8 sourcesComplete;
        OraclesLink.PerSourceRequirements requirements;
        uint8 minSourcesComplete;
        OraclesLinkInt256.AggregationMethod aggregationMethod;
    }

    // map sourceResponsesId => actual oracle responses
    mapping(bytes32 => ResponseInt256[]) internal sourceResponsesIdToResponses;

    // map each source responses id to a oracles link id for aggregation of the whole oracle link
    mapping(bytes32 => bytes32) internal sourceResponsesIdToOraclesLinkId;

    // map each oracles link id to the OraclesLinkRequest data
    mapping(bytes32 => OraclesLinkRequest) internal oraclesLinkIdToOraclesLinkRequest;

    // map each outgoing chainlink request id to respective source response id to be able to link the answer to a source for aggregation
    mapping(bytes32 => bytes32) internal chainlinkRequestIdToSourceResponsesId;

    // map each outgoing chainlink request id to respective oracles link id
    mapping(bytes32 => bytes32) internal chainlinkRequestIdToOraclesLinkId;

    // map each outgoing chainlink request id to the oracle Level handling the chainlink request
    mapping(bytes32 => OracleLevel) internal chainlinkRequestIdToOracleLevel;

    // map for flag if the responses for a source are marked as complete
    // sourceReponsesId => bool
    mapping(bytes32 => bool) internal isSourceResponsesComplete;

    // map for oraclesLinkId to all assigned source responses ids
    mapping(bytes32 => bytes32[]) internal oraclesLinkIdToSourceResponsesIds;

    /**
     * @notice The method called when an answer is received for a chainlink int256 request, overrides the OraclesChainlinkHandler virtual method called there
     * @param _chainlinkRequestId The ID that was generated for the Chainlink Request
     * @param _answer The answer provided by the Oracle
     */
    function handleChainlinkAnswerInt256(bytes32 _chainlinkRequestId, int256 _answer) internal override {
        // retrieve assigned OraclesLinkRequest
        bytes32 oraclesLinkId = chainlinkRequestIdToOraclesLinkId[_chainlinkRequestId];
        OraclesLinkRequest storage oraclesLinkRequest = oraclesLinkIdToOraclesLinkRequest[oraclesLinkId];

        require(oraclesLinkRequest.exists, "Oracles Link for this Chainlink Request id does not exist");

        // retrieve oracle level and responses for the respective responses array for the source that this chainlink request id is assigned to
        OracleLevel oracleLevel = chainlinkRequestIdToOracleLevel[_chainlinkRequestId];

        bytes32 sourceResponsesId = chainlinkRequestIdToSourceResponsesId[_chainlinkRequestId];
        ResponseInt256[] storage responses = sourceResponsesIdToResponses[sourceResponsesId];

        // add oracle response
        responses.push(ResponseInt256(_answer, oracleLevel));

        // delete chainlink request id mappings
        delete chainlinkRequestIdToSourceResponsesId[_chainlinkRequestId];
        delete chainlinkRequestIdToOracleLevel[_chainlinkRequestId];
        delete chainlinkRequestIdToOraclesLinkId[_chainlinkRequestId];

        emit ChainlinkAnswerInt256Handled(_chainlinkRequestId, sourceResponsesId, oraclesLinkId, _answer);

        // check if source is not yet marked as complete
        // if not and if the requirements for the source responses are fulfilled => mark source as complete
        if (!isSourceResponsesComplete[sourceResponsesId] && isPerSourceRequirementsFulfilled(responses, oraclesLinkRequest.requirements)) {
            isSourceResponsesComplete[sourceResponsesId] = true;
            emit OraclesLinkSourceComplete(oraclesLinkId, sourceResponsesId);
            handleSourceComplete(oraclesLinkId, oraclesLinkRequest);
        }
    }

    function handleSourceComplete(bytes32 _oraclesLinkId, OraclesLinkRequest storage _oraclesLinkRequest) private {
        // new source has been marked as complete => check if minSourcesComplete is fulfilled for the oraclesLink
        _oraclesLinkRequest.sourcesComplete++;
        if (_oraclesLinkRequest.sourcesComplete >= _oraclesLinkRequest.minSourcesComplete) {
            // oracles link is complete! => finish oraclesLink
            handleOraclesLinkComplete(_oraclesLinkId, _oraclesLinkRequest);
        }
    }

    function handleOraclesLinkComplete(bytes32 _oraclesLinkId, OraclesLinkRequest storage _oraclesLinkRequest) private {
        // oracles link fulfills all requirements
        // 1. get all sourceResponsesIds for the oraclesLinkId
        bytes32[] storage sourceResponsesIds = oraclesLinkIdToSourceResponsesIds[_oraclesLinkId];

        int256[] memory sourceResultsTotal = new int256[](sourceResponsesIds.length);

        uint8 sourceResultsIndex = 0;
        // 2. aggregate responses per source
        for (uint8 i = 0; i < sourceResponsesIds.length; i++) {
            bytes32 sourceResponsesId = sourceResponsesIds[i];
            ResponseInt256[] storage responses = sourceResponsesIdToResponses[sourceResponsesId];
            if (responses.length > 0 && _oraclesLinkRequest.aggregationMethod == OraclesLinkInt256.AggregationMethod.Median) {
                sourceResultsTotal[sourceResultsIndex] = Median.calculate(responsesInt256ToInt256(responses));
                emit OraclesLinkSourceAggregated(_oraclesLinkId, sourceResponsesId, sourceResultsTotal[sourceResultsIndex]);
                sourceResultsIndex++;
            }
            // clean up mappings for this source once aggregated
            delete sourceResponsesIdToResponses[sourceResponsesId];
            delete sourceResponsesIdToOraclesLinkId[sourceResponsesId];
            delete isSourceResponsesComplete[sourceResponsesId];
        }
        int256[] memory sourceResultsNonEmpty = new int256[](sourceResultsIndex);
        for (uint8 i = 0; i < sourceResultsIndex; i++) {
            sourceResultsNonEmpty[i] = sourceResultsTotal[i];
        }

        // 2. aggregate sources
        int256 result;
        if (_oraclesLinkRequest.aggregationMethod == OraclesLinkInt256.AggregationMethod.Median) {
            result = Median.calculate(sourceResultsNonEmpty);
        }
        emit OraclesLinkAggregated(_oraclesLinkId, result);

        // 3. cleanup mappings etc.
        delete oraclesLinkIdToOraclesLinkRequest[_oraclesLinkId];
        delete oraclesLinkIdToSourceResponsesIds[_oraclesLinkId];

        // 4. return answer by calling fulfill method that is overriden by user contract
        emit OraclesLinkFulfilled(_oraclesLinkId);
        fulfillOraclesLinkInt256(_oraclesLinkId, result);
    }

    function responsesInt256ToInt256(ResponseInt256[] storage responses) private view returns (int256[] memory int256Responses) {
        int256Responses = new int256[](responses.length);

        for (uint8 i = 0; i < responses.length; i++) {
            int256Responses[i] = responses[i].answer;
        }

        return int256Responses;
    }

    function addOraclesLink() internal returns (bytes32 oraclesLinkId, bytes32 seed) {
        oraclesLinkId = keccak256(abi.encodePacked(this, oracleLinksCount));
        seed = keccak256(abi.encodePacked(oraclesLinkId, msg.sender));

        oracleLinksCount += 1;

        return (oraclesLinkId, seed);
    }

    function getOraclesWithJob(
        OraclesLink.PerSourceRequirements memory _requirements,
        bytes32 _seed,
        bytes32 _jobType
    )
        internal
        returns (
            address[] memory oracleAddresses,
            bytes32[] memory jobIds,
            uint256[] memory payments,
            OracleLevel[] memory oracleLevels
        )
    {
        uint8 totalCount = _requirements.seniorOraclesCount + _requirements.matureOraclesCount + _requirements.noviceOraclesCount;

        oracleAddresses = new address[](totalCount);
        jobIds = new bytes32[](totalCount);
        payments = new uint256[](totalCount);
        oracleLevels = new OracleLevel[](totalCount);

        (
            uint256[] memory seniorOracleIndices,
            uint256[] memory matureOracleIndices,
            uint256[] memory noviceOracleIndices
        ) = getRandomOracleIndices(_requirements, _seed, _jobType);

        uint8 counter = 0;

        for (uint8 i = 0; i < seniorOracleIndices.length; i++) {
            // get oracle and job details for oracle at index
            (address oracleAddress, bytes32 jobId, uint256 cost) = getSeniorOracleWithJob(seniorOracleIndices[i], _jobType);
            oracleAddresses[counter] = oracleAddress;
            jobIds[counter] = jobId;
            payments[counter] = cost;
            oracleLevels[counter] = OracleLevel.Senior;
            counter++;
        }

        for (uint8 i = 0; i < matureOracleIndices.length; i++) {
            // get oracle and job details for oracle at index
            (address oracleAddress, bytes32 jobId, uint256 cost) = getMatureOracleWithJob(matureOracleIndices[i], _jobType);
            oracleAddresses[counter] = oracleAddress;
            jobIds[counter] = jobId;
            payments[counter] = cost;
            oracleLevels[counter] = OracleLevel.Mature;
            counter++;
        }

        for (uint8 i = 0; i < noviceOracleIndices.length; i++) {
            // get oracle and job details for oracle at index
            (address oracleAddress, bytes32 jobId, uint256 cost) = getNoviceOracleWithJob(noviceOracleIndices[i], _jobType);
            oracleAddresses[counter] = oracleAddress;
            jobIds[counter] = jobId;
            payments[counter] = cost;
            oracleLevels[counter] = OracleLevel.Novice;
            counter++;
        }

        return (oracleAddresses, jobIds, payments, oracleLevels);
    }

    function isPerSourceRequirementsFulfilled(ResponseInt256[] storage _responses, OraclesLink.PerSourceRequirements storage _requirements)
        private
        view
        returns (bool)
    {
        // check if total min is reached
        if (_responses.length < _requirements.totalMinResponses) {
            return false;
        }

        // check if min responses for oracle levels have been reached
        // 1. get the respones count per oracle level
        uint8 seniorOraclesResponses = 0;
        uint8 matureOraclesResponses = 0;
        uint8 noviceOraclesResponses = 0;
        for (uint8 i = 0; i < _responses.length; i++) {
            if (_responses[i].oracleLevel == OracleLevel.Senior) {
                seniorOraclesResponses++;
            }
            if (_responses[i].oracleLevel == OracleLevel.Senior) {
                matureOraclesResponses++;
            }
            if (_responses[i].oracleLevel == OracleLevel.Senior) {
                noviceOraclesResponses++;
            }
        }

        // 2. check if min responses for each oracle level has been reached
        if (seniorOraclesResponses < _requirements.seniorMinResponses) {
            return false;
        }
        if (matureOraclesResponses < _requirements.matureMinResponses) {
            return false;
        }
        if (noviceOraclesResponses < _requirements.noviceMinResponses) {
            return false;
        }

        // min responses for total and each oracle level are fulfilled!
        return true;
    }

    modifier onlyValidRequirements(OraclesLink.PerSourceRequirements memory _requirements) {
        uint8 totalCount = _requirements.seniorOraclesCount + _requirements.matureOraclesCount + _requirements.noviceOraclesCount;
        require(_requirements.totalMinResponses <= totalCount, "totalMinResponses must be < total oracles count");

        require(_requirements.noviceOraclesCount <= MAX_ORACLES_PER_LEVEL, "Cannot have more than 21 oracles per level");
        require(_requirements.matureOraclesCount <= MAX_ORACLES_PER_LEVEL, "Cannot have more than 21 oracles per level");
        require(_requirements.seniorOraclesCount <= MAX_ORACLES_PER_LEVEL, "Cannot have more than 21 oracles per level");

        // enforce security with senior oracles
        require(_requirements.seniorOraclesCount > 0, "Senior oracles count must be > 0");
        require(_requirements.seniorMinResponses > 0, "Min senior responses must be > 0");
        require(
            _requirements.seniorOraclesCount > (_requirements.totalMinResponses / 2),
            "Half of min answers must be senior oracles answers (seniorOraclesCount > totalMinResponses/2)"
        );

        _;
    }
}
