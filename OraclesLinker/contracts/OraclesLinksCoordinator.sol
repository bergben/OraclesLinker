pragma solidity 0.6.8;

import "./OraclesLink.sol";
import "./RandomOraclesProviderHost.sol";


/** SPDX-License-Identifier: MIT*/

/**
 * @title OraclesLinksCoordinator is a contract which manages OraclesLinks
 */
contract OraclesLinksCoordinator is RandomOraclesProviderHost {
    // event OraclesLinkRequested(bytes32 indexed id);
    // event OraclesLinkFulfilled(bytes32 indexed id);
    // event OraclesLinkCancelled(bytes32 indexed id);

    uint8 private constant MAX_ORACLES_PER_LEVEL = 21;
    uint256 private oracleLinksCount = 1;

    // struct OraclesLinkRequest {
    //     address sender;
    //     int256[] responses;
    // }

    // map each outgoing chainlink request id to a oracle link id
    mapping(bytes32 => bytes32) internal chainlinkRequestIdsToOraclesLinkIds;

    // // Local Request ID => addresses of oracles the requests were sent to
    // mapping(bytes32 => address[]) private pendingOracleLinks;

    // // Requester's Request ID => Requester
    // mapping(bytes32 => Requester) internal requesters;

    function addOraclesLink() internal returns (bytes32 oraclesLinkId, bytes32 seed) {
        oraclesLinkId = keccak256(abi.encodePacked(this, oracleLinksCount));
        // todo:
        // require(requesters[oraclesLinkId].sender == address(0), "oraclesLinkId already in-use");
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
            uint256[] memory payments
        )
    {
        uint8 totalCount = _requirements.seniorOraclesCount + _requirements.matureOraclesCount + _requirements.noviceOraclesCount;

        oracleAddresses = new address[](totalCount);
        jobIds = new bytes32[](totalCount);
        payments = new uint256[](totalCount);

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
            counter++;
        }

        for (uint8 i = 0; i < matureOracleIndices.length; i++) {
            // get oracle and job details for oracle at index
            (address oracleAddress, bytes32 jobId, uint256 cost) = getMatureOracleWithJob(matureOracleIndices[i], _jobType);
            oracleAddresses[counter] = oracleAddress;
            jobIds[counter] = jobId;
            payments[counter] = cost;
            counter++;
        }

        for (uint8 i = 0; i < noviceOracleIndices.length; i++) {
            // get oracle and job details for oracle at index
            (address oracleAddress, bytes32 jobId, uint256 cost) = getNoviceOracleWithJob(noviceOracleIndices[i], _jobType);
            oracleAddresses[counter] = oracleAddress;
            jobIds[counter] = jobId;
            payments[counter] = cost;
            counter++;
        }

        return (oracleAddresses, jobIds, payments);
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
