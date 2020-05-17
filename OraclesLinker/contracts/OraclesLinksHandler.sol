pragma solidity 0.6.8;


/** SPDX-License-Identifier: MIT*/

/**
 * @title OraclesLinksHandler is a contract which manages OraclesLinks
 */
contract OraclesLinksHandler {
    event OraclesLinkRequested(bytes32 indexed id);
    event OraclesLinkFulfilled(bytes32 indexed id);
    event OraclesLinkCancelled(bytes32 indexed id);

    uint256 private oracleLinksCount = 1;
    mapping(bytes32 => address) private pendingOraclesLinks;

    function addOraclesLink() internal returns (bytes32 oraclesLinkId, bytes32 seed) {
        oraclesLinkId = keccak256(abi.encodePacked(this, oracleLinksCount));
        seed = keccak256(abi.encodePacked(oraclesLinkId, msg.sender));

        // todo:
        pendingOraclesLinks[oraclesLinkId] = address(0);

        emit OraclesLinkRequested(oraclesLinkId);

        oracleLinksCount += 1;

        return (oraclesLinkId, seed);
    }

    /**
     * @dev Reverts if the sender is not the RandomOraclesProvider handling the OraclesLink.
     * Emits OraclesLinkFulfilled event.
     * @param _oraclesLinkId The oraclesLink ID for fulfillment
     */
    modifier recordOraclesLinkFulfilled(bytes32 _oraclesLinkId) {
        require(msg.sender == pendingOraclesLinks[_oraclesLinkId], "Source must be the RandomOraclesProvider handling the OraclesLink");
        delete pendingOraclesLinks[_oraclesLinkId];
        emit OraclesLinkFulfilled(_oraclesLinkId);
        _;
    }
}
