pragma solidity 0.6.8;

import "./OraclesLink.sol";
import "./Utils.sol";


/** SPDX-License-Identifier: MIT*/

/**
 * @title Library for Oracles Links for Int256
 */
library OraclesLinkInt256 {
    using OraclesLink for OraclesLink.Base;
    enum AggregationMethod {Median, None}

    struct Source {
        bytes32 url;
        bytes32 path;
        uint256 multiplier;
        bool exists;
    }

    struct Request {
        OraclesLink.Base base;
        AggregationMethod aggregationMethod;
        Source[] sources;
    }

    /**
     * @notice Initializes a OraclesLinkInt256 request
     * @dev Sets the ID, callback address, and callback function signature on the request
     * @param self The uninitialized request
     * @param _callbackAddress The callback address
     * @param _callbackFunction The callback function signature
     * @return The initialized request
     */
    function initialize(
        Request memory self,
        uint8 _sources,
        address _callbackAddress,
        bytes4 _callbackFunction
    ) internal pure returns (OraclesLinkInt256.Request memory) {
        self.base.callbackAddress = _callbackAddress;
        self.base.callbackFunctionId = _callbackFunction;

        self.sources = new Source[](_sources);

        // set default aggregation method to Median
        self.aggregationMethod = AggregationMethod.Median;
        return self;
    }

    function addSource(
        Request memory self,
        string memory _url,
        string memory _path,
        uint256 _multiplier
    ) internal pure {
        uint8 index = 0;
        while (self.sources[index].exists) {
            index++;
        }
        self.sources[index] = Source(Utils.stringToBytes32(_url), Utils.stringToBytes32(_path), _multiplier, true);
    }

    function setAggregationMethod(Request memory self, AggregationMethod _aggregationMethod) internal pure {
        self.aggregationMethod = _aggregationMethod;
    }
}
