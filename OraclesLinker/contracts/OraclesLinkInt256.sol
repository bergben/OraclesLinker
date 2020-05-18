pragma solidity 0.6.8;

import "./OraclesLinkRequirements.sol";
import "./OraclesLink.sol";


/** SPDX-License-Identifier: MIT*/

/**
 * @title Library for Oracles Links for Int256
 */
library OraclesLinkInt256 {
    using OraclesLinkRequirements for OraclesLinkRequirements.Requirements;
    enum AggregationMethod {Median}

    struct Source {
        string url;
        string path;
        int256 multiplier;
        bool exists;
    }

    struct Request {
        OraclesLinkRequirements.Requirements requirements;
        AggregationMethod aggregationMethod;
        Source[] sources;
    }

    /**
     * @notice Initializes a OraclesLinkInt256 request
     * @dev Sets the ID, callback address, and callback function signature on the request
     * @param self The uninitialized request
     * @param _sources The amount of sources
     * @return The initialized request
     */
    function initialize(
        Request memory self,
        uint8 _sources,
        uint8 _minSourcesComplete
    ) internal pure returns (OraclesLinkInt256.Request memory) {
        self.sources = new Source[](_sources);

        // set default aggregation method to Median
        self.aggregationMethod = AggregationMethod.Median;
        // set security level default (sets default requirement settings)
        self.requirements.setSecurityLevel(OraclesLink.SecurityLevel.Default);

        self.requirements.minSourcesComplete = _minSourcesComplete;

        return self;
    }

    function addSource(
        Request memory self,
        string memory _url,
        string memory _path,
        int256 _multiplier
    ) internal pure {
        uint8 index = 0;
        while (self.sources[index].exists) {
            index++;
        }
        self.sources[index] = Source(_url, _path, _multiplier, true);
    }

    function setSecurityLevel(Request memory self, OraclesLink.SecurityLevel _securityLevel) internal pure {
        self.requirements.setSecurityLevel(_securityLevel);
    }

    function setAggregationMethod(Request memory self, AggregationMethod _aggregationMethod) internal pure {
        self.aggregationMethod = _aggregationMethod;
    }
}
