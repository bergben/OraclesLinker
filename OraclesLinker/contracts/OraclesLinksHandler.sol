pragma solidity 0.6.8;

import "./OraclesLink.sol";


/** SPDX-License-Identifier: MIT*/

/**
 * @title OraclesLinksHandler is a contract which manages OraclesLinks
 */
contract OraclesLinksHandler {
    event OraclesLinkRequested(bytes32 indexed id);
    event OraclesLinkFulfilled(bytes32 indexed id);
    event OraclesLinkCancelled(bytes32 indexed id);

    uint8 private constant MAX_ORACLES_PER_LEVEL = 21;

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

    modifier onlyValidRequirements(OraclesLink.PerSourceRequirements memory _requirements) {
        // enforce security with senior oracles
        require(_requirements.seniorOraclesCount > 0, "Senior oracles count must be > 0");
        require(_requirements.seniorMinResponses > 0, "Min senior responses must be > 0");
        require(
            _requirements.seniorOraclesCount > (_requirements.totalMinResponses / 2),
            "Half of min answers must be senior oracles answers (seniorOraclesCount > totalMinResponses/2)"
        );

        require(_requirements.noviceOraclesCount <= MAX_ORACLES_PER_LEVEL, "Cannot have more than 21 oracles per level");
        require(_requirements.matureOraclesCount <= MAX_ORACLES_PER_LEVEL, "Cannot have more than 21 oracles per level");
        require(_requirements.seniorOraclesCount <= MAX_ORACLES_PER_LEVEL, "Cannot have more than 21 oracles per level");

        _;
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
