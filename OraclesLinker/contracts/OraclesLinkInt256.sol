pragma solidity 0.6.8;


/** SPDX-License-Identifier: MIT*/

/**
 * @title Library for Oracles Links for Int256
 */
library OraclesLinkInt256 {
    enum AggregationMethod {Median, None}

    struct Source {
        bytes32[] urls;
        bytes32[] paths;
        uint256[] multipliers;
    }

    struct Request {
        address callbackAddress;
        bytes4 callbackFunctionId;
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
        address _callbackAddress,
        bytes4 _callbackFunction
    ) internal pure returns (OraclesLinkInt256.Request memory) {
        self.callbackAddress = _callbackAddress;
        self.callbackFunctionId = _callbackFunction;
        return self;
    }

    function addSource(
        Request memory self,
        bytes32 _url,
        bytes32 _path,
        uint256 _multiplier
    ) internal pure {
        self.sources.push(_url, _path, _multiplier);
    }

    function setAggregationMethod(Request memory self, AggregationMethod _aggregationMethod) internal pure {
        self.aggregationMethod = _aggregationMethod;
    }
}
