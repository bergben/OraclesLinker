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

    function buildOraclesLinkInt256(
        uint8 _sources,
        address _callbackAddress,
        bytes4 _callbackFunctionSignature
    ) internal pure returns (OraclesLinkInt256.Request memory) {
        OraclesLinkInt256.Request memory req;
        return req.initialize(_sources, _callbackAddress, _callbackFunctionSignature);
    }

    function sendOraclesLinkInt256(OraclesLinkInt256.Request memory req, uint256 _payment) internal returns (bytes32 oraclesLinkId) {
        bytes32 seed;
        (oraclesLinkId, seed) = addOraclesLink();

        return oraclesLinkId;
    }
}
