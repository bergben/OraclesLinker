pragma solidity 0.6.8;

import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";


/** SPDX-License-Identifier: MIT*/

/**
 * @title OraclesChainlinkHandler is a contract which interacts with the chainlink nodes network
 */
abstract contract OraclesChainlinkHandler is ChainlinkClient {
    /**
     * @notice The method called when an answer is received for a chainlink int256 request, to be overriden by the OraclesLinksCoordinator
     * @param _chainlinkRequestId The ID that was generated for the Chainlink Request
     * @param _answer The answer provided by the Oracle
     */
    function handleChainlinkAnswerInt256(bytes32 _chainlinkRequestId, int256 _answer) internal virtual;

    function sendInt256ChainlinkRequest(
        string memory _url,
        string memory _path,
        int256 _multiplier,
        address _oracleAddress,
        bytes32 _jobId,
        uint256 _payment
    ) internal returns (bytes32 chainlinkRequestId) {
        // uncomment the following two lines for mocking locally (for mocking the answers, also uncomment recordChainlinkFulfillment)
        chainlinkRequestId = keccak256(abi.encodePacked(_url, _oracleAddress, _jobId));
        return chainlinkRequestId;

        Chainlink.Request memory req = buildChainlinkRequest(_jobId, address(this), this.fulfillChainlinkInt256.selector);
        // Adds a URL with the key "get" to the request parameters
        req.add("get", _url);
        // Uses input param (dot-delimited string) as the "path" in the request parameters
        req.add("path", _path);
        // Adds an integer with the key "times" to the request parameters
        req.addInt("times", _multiplier);
        // Sends the request with the amount of payment specified to the oracle
        return sendChainlinkRequestTo(_oracleAddress, req, _payment);
    }

    function fulfillChainlinkInt256(bytes32 _chainlinkRequestId, int256 _answer)
        external
    // Use recordChainlinkFulfillment to ensure only the requesting oracle can fulfill
    // recordChainlinkFulfillment(_chainlinkRequestId)
    {
        handleChainlinkAnswerInt256(_chainlinkRequestId, _answer);
    }
}
