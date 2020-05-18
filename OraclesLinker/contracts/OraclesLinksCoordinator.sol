pragma solidity 0.6.8;

import "./OraclesLink.sol";
import "./RandomOraclesProviderHost.sol";
import "./OraclesChainlinkHandler.sol";


/** SPDX-License-Identifier: MIT*/

/**
 * @title OraclesLinksCoordinator is a contract which manages OraclesLinks
 */
abstract contract OraclesLinksCoordinator is RandomOraclesProviderHost, OraclesChainlinkHandler {
    enum OracleLevel {Novice, Mature, Senior}

    /**
     * @notice The fulfill method for the calling smart contract that overrides it as callback
     * @param _oraclesLinkId The ID that was generated for the OraclesLink
     * @param _answer The answer provided by the Oracles
     */
    function fulfillOraclesLinkInt256(bytes32 _oraclesLinkId, int256 _answer) internal virtual;

    // event OraclesLinkRequested(bytes32 indexed id);
    // event OraclesLinkFulfilled(bytes32 indexed id);
    // event OraclesLinkCancelled(bytes32 indexed id);

    uint8 private constant MAX_ORACLES_PER_LEVEL = 21;
    uint256 private oracleLinksCount = 1;

    struct OraclesLinkRequest {
        bytes32 id;
        bool exists;
        int256[] sourceResponses;
    }

    // map each outgoing chainlink request id to a oracle link id
    mapping(bytes32 => OraclesLinkRequest) internal chainlinkRequestIdToOraclesLinkRequest;

    // map each outgoing chainlink request id to the index of the respective source in the OraclesLinkRequest sourceResponses array
    mapping(bytes32 => uint8) internal chainlinkRequestIdsToSourceIndex;

    // map each outgoing chainlink request id to the oracle Level handling the chainlink request
    mapping(bytes32 => OracleLevel) internal chainlinkRequestIdToOracleLevel;

    // // Local Request ID => addresses of oracles the requests were sent to
    // mapping(bytes32 => address[]) private pendingOracleLinks;

    // // Requester's Request ID => Requester
    // mapping(bytes32 => Requester) internal requesters;

    /**
     * @notice The method called when an answer is received for a chainlink int256 request, overrides the OraclesChainlinkHandler virtual method called there
     * @param _chainlinkRequestId The ID that was generated for the Chainlink Request
     * @param _answer The answer provided by the Oracle
     */
    function handleChainlinkAnswerInt256(bytes32 _chainlinkRequestId, int256 _answer) internal override {
        OraclesLinkRequest storage oraclesLinkRequest = chainlinkRequestIdToOraclesLinkRequest[_chainlinkRequestId];
        require(oraclesLinkRequest.exists, "Oracles Link for this Chainlink Request id does not exist");
        uint8 sourceIndex = chainlinkRequestIdsToSourceIndex[_chainlinkRequestId];
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

    modifier onlyValidRequirements(OraclesLink.PerSourceRequirements memory _requirements) {
        // enforce security with senior oracles
        require(_requirements.seniorOraclesCount > 0, "Senior oracles count must be > 0");
        require(_requirements.seniorMinResponses > 0, "Min senior responses must be > 0");
        require(
            _requirements.seniorOraclesCount > (_requirements.totalMinResponses / 2),
            "Half of min answers must be senior oracles answers (seniorOraclesCount > totalMinResponses/2)"
        );

        require(_requirements.noviceOraclesCount <= MAX_ORACLES_PER_LEVEL, "Cannot have more than 21 oracles per level");
        require(_requirements.matureOraclesCount <= MAX_ORACLES_PER_LEVEL, "Cannot have more than 21 oracles per level");
        require(_requirements.seniorOraclesCount <= MAX_ORACLES_PER_LEVEL, "Cannot have more than 21 oracles per level");

        _;
    }
}
