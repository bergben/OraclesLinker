pragma solidity 0.6.8;

import "oracles-link-provider/contracts/RandomOraclesProvider/OraclesLinkProvider.sol";

import "./OraclesLinksBuilder.sol";
import "./OraclesLinksCoordinator.sol";


/** SPDX-License-Identifier: MIT*/

/**
 * @title OraclesLinker is a contract which creates requests to multiple chainlink oracles picked at random by the RandomOraclesProvider
 */
abstract contract OraclesLinker is OraclesLinksBuilder, OraclesLinksCoordinator {
    function sendOraclesLinkInt256(OraclesLinkInt256.Request memory _req, uint256 _payment)
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
            _req.requirements.minSourcesComplete
        );

        // send out each source to the random oracles
        for (uint8 i = 0; i < _req.sources.length; i++) {
            bytes32 sourceId = keccak256(abi.encodePacked(seed, i));
            sourceResponsesIdToOraclesLinkId[sourceId] = oraclesLinkId;
            isSourceResponsesComplete[sourceId] = false;
            string memory url = _req.sources[i].url;
            string memory path = _req.sources[i].path;
            int256 multiplier = _req.sources[i].multiplier;

            for (uint8 j = 0; j < oracleAddresses.length; j++) {
                bytes32 chainlinkRequestId = sendInt256ChainlinkRequest(url, path, multiplier, oracleAddresses[j], jobIds[j], payments[j]);

                chainlinkRequestIdToOracleLevel[chainlinkRequestId] = oracleLevels[j];
                chainlinkRequestIdsToSourceResponsesId[chainlinkRequestId] = sourceId;
            }
        }

        return oraclesLinkId;
    }
}
