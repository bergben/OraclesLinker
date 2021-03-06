pragma solidity 0.6.8;

import "./OraclesLinkInt256.sol";

import "./OraclesLinksBuilder.sol";
import "./OraclesLinksCoordinator.sol";


/** SPDX-License-Identifier: MIT*/

/**
 * @title OraclesLinker is a contract which creates requests to multiple chainlink oracles picked at random by the RandomOraclesProvider
 */
abstract contract OraclesLinker is OraclesLinksBuilder, OraclesLinksCoordinator {
    function sendOraclesLinkInt256(OraclesLinkInt256.Request memory _req)
        internal
        onlyValidRequirements(_req.requirements.perSource)
        returns (bytes32 oraclesLinkId)
    {
        bytes32 seed;
        (oraclesLinkId, seed) = addOraclesLink();

        bytes32 jobType = "HttpGetInt256";

        (
            address[] memory oracleAddresses,
            bytes32[] memory jobIds,
            uint256[] memory payments,
            OracleLevel[] memory oracleLevels
        ) = getOraclesWithJob(_req.requirements.perSource, seed, jobType);

        oraclesLinkIdToOraclesLinkRequest[oraclesLinkId] = OraclesLinkRequest(
            true,
            0,
            _req.requirements.perSource,
            _req.requirements.minSourcesComplete,
            _req.aggregationMethod
        );

        sendChainlinkInt256Requests(oraclesLinkId, seed, _req.sources, oracleAddresses, jobIds, payments, oracleLevels);

        emit OraclesLinkRequested(oraclesLinkId);

        return oraclesLinkId;
    }

    function sendChainlinkInt256Requests(
        bytes32 _oraclesLinkId,
        bytes32 _seed,
        OraclesLinkInt256.Source[] memory _sources,
        address[] memory _oracleAddresses,
        bytes32[] memory _jobIds,
        uint256[] memory _payments,
        OracleLevel[] memory _oracleLevels
    ) private {
        // send out each source to the random oracles
        for (uint8 i = 0; i < _sources.length; i++) {
            bytes32 sourceResponsesId = keccak256(abi.encodePacked(_seed, i));
            sourceResponsesIdToOraclesLinkId[sourceResponsesId] = _oraclesLinkId;
            string memory url = _sources[i].url;
            string memory path = _sources[i].path;
            int256 multiplier = _sources[i].multiplier;

            emit OraclesLinkSourceCreated(_oraclesLinkId, sourceResponsesId, url);

            for (uint8 j = 0; j < _oracleAddresses.length; j++) {
                bytes32 chainlinkRequestId = sendInt256ChainlinkRequest(url, path, multiplier, _oracleAddresses[j], _jobIds[j], _payments[j]);

                chainlinkRequestIdToOracleLevel[chainlinkRequestId] = _oracleLevels[j];
                chainlinkRequestIdToSourceResponsesId[chainlinkRequestId] = sourceResponsesId;
                chainlinkRequestIdToOraclesLinkId[chainlinkRequestId] = _oraclesLinkId;

                emit OraclesLinkChainlinkCreated(
                    _oraclesLinkId,
                    sourceResponsesId,
                    chainlinkRequestId,
                    _oracleAddresses[j],
                    _jobIds[j],
                    _payments[j]
                );
            }
        }
    }
}
