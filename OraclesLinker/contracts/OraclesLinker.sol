pragma solidity 0.6.8;

import "oracles-link-provider/contracts/RandomOraclesProvider/OraclesLinkProvider.sol";

import "./OraclesLinkInt256.sol";
import "./RandomOraclesProviderHost.sol";
import "./OraclesLinksHandler.sol";


/** SPDX-License-Identifier: MIT*/

/**
 * @title OraclesLinker is a contract which creates requests to multiple chainlink oracles picked at random by the RandomOraclesProvider
 */
contract OraclesLinker is OraclesLinksHandler, RandomOraclesProviderHost {
    using OraclesLinkInt256 for OraclesLinkInt256.Request;

    uint8 private constant MAX_TOTAL_LEVEL_REQUESTS = 21;

    function buildOraclesLinkInt256(
        uint8 _sources,
        address _callbackAddress,
        bytes4 _callbackFunctionSignature
    ) internal pure returns (OraclesLinkInt256.Request memory) {
        OraclesLinkInt256.Request memory req;
        return req.initialize(_sources, _callbackAddress, _callbackFunctionSignature);
    }

    function sendOraclesLinkInt256(OraclesLinkInt256.Request memory _req, uint256 _payment)
        internal
        onlyValidRequirements(_req.base.requirements)
        returns (bytes32 oraclesLinkId)
    {
        bytes32 seed;
        (oraclesLinkId, seed) = addOraclesLink();

        bytes32 jobType = "HttpGetInt256";
        sendOraclesLink(_req, _payment, seed, jobType);

        return oraclesLinkId;
    }

    function sendOraclesLink(
        OraclesLinkInt256.Request memory _req,
        uint256 _payment,
        bytes32 _seed,
        bytes32 _jobType
    ) private {
        // Todo: Payment with transferAndCall compatibility, implement similar to how in PreCoordinator and adapt from LinkTokenReceiver.
        // Aggregation here from sources is easy, without rounds
        // Todo: add requirement -> there have to be this many oracles available for a certain jobType / level

        // senior oracles
        uint256[] memory seniorOracleIndices = randomOraclesProvider.getRandomSeniorIndices(
            _req.base.requirements.seniorOraclesCount,
            _jobType,
            _seed
        );

        // mature oracles
        uint256[] memory matureOracleIndices = randomOraclesProvider.getRandomMatureIndices(
            _req.base.requirements.seniorOraclesCount,
            _jobType,
            _seed
        );

        // novice oracles
        uint256[] memory noviceOracleIndices = randomOraclesProvider.getRandomNoviceIndices(
            _req.base.requirements.seniorOraclesCount,
            _jobType,
            _seed
        );
    }
}
