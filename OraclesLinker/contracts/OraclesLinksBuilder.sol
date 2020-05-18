pragma solidity 0.6.8;

import "./OraclesLinkInt256.sol";


/** SPDX-License-Identifier: MIT*/

/**
 * @title OraclesLinksBuilder is a contract which builds OracleLinks
 */
contract OraclesLinksBuilder {
    using OraclesLinkInt256 for OraclesLinkInt256.Request;

    function buildOraclesLinkInt256(uint8 _sources, uint8 _minSourcesComplete) internal pure returns (OraclesLinkInt256.Request memory) {
        OraclesLinkInt256.Request memory req;
        return req.initialize(_sources, _minSourcesComplete);
    }
}
