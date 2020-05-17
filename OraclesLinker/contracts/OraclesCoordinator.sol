pragma solidity >=0.5.17;

import "./OraclesLink.sol";


contract OraclesCoordinator {
    function getInt256Link(
        string memory _url,
        string memory _path,
        uint256 memory times,
        OraclesLink.Requirements memory _requirements
    ) internal onlyLINK checkCallbackAddress(_callbackAddress) returns (bytes32 oraclesLinkId) {
        // Todo: Payment with transferAndCall compatibility, implement similar to how in PreCoordinator and adapt from LinkTokenReceiver.
        // Todo: add requirement -> there have to be this many oracles available for a certain jobType / level
        // Todo: I might need global nonce when creating a certain OraclesLinkId, see PreCoordinator
        // Todo: add OraclesCoordinator which does this
        // OraclesLinker instead is the one that aggregates everything in the end, maybes using OraclesLinkAggregator

        // loop over the selection method and aggregate the oracles in arrays
        address[] oracleAddresses;
        bytes32[] jobIds;
        uint256[] payments;
        uint256[] alreadySelected;
        uint256 totalOracles = 0;

        // select senior nodes
        for (uint256 i = 0; i < _requirements.seniorOraclesCount; i++) {
            (oracleAddresses[totalOracles], jobIds[totalOracles], payments[totalOracles], alreadySelected[i]) = OraclesSelector.select(
                OraclesLink.JobType.HttpGetInt256,
                OraclesLink.OraclesLevel.Senior,
                totalOracles,
                alreadySelected
            );
            totalOracles++;
        }
        delete alreadySelected;

        // select mature nodes
        for (uint256 i = 0; i < _requirements.matureOraclesCount; i++) {
            (oracleAddresses[totalOracles], jobIds[totalOracles], payments[totalOracles], alreadySelected[i]) = OraclesSelector.select(
                OraclesLink.JobType.HttpGetInt256,
                OraclesLink.OraclesLevel.Mature,
                totalOracles,
                alreadySelected
            );
            totalOracles++;
        }
        delete alreadySelected;

        // select novice nodes
        for (uint256 i = 0; i < _requirements.noviceOraclesCount; i++) {
            (oracleAddresses[totalOracles], jobIds[totalOracles], payments[totalOracles], alreadySelected[i]) = OraclesSelector.select(
                OraclesLink.JobType.HttpGetInt256,
                OraclesLink.OraclesLevel.Novice,
                totalOracles,
                alreadySelected
            );
            totalOracles++;
        }
        delete alreadySelected;

        // send out requests
        createRequests();
        // return oraclesLinkId? (or requestIds?)
    }
}
