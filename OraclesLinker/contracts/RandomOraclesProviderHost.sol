pragma solidity 0.6.8;

import "oracles-link-provider/contracts/RandomOraclesProvider/OraclesLinkProvider.sol";
import "./OraclesLink.sol";


/** SPDX-License-Identifier: MIT*/

/**
 * @title RandomOraclesProviderHost is a contract who hosts the connection to the RandomOraclesProvider
 */
contract RandomOraclesProviderHost {
    event RandomOraclesProviderAddressSet(address randomOraclesProviderAddress);

    address private PUBLIC_RANDOM_ORACLES_PROVIDER_ADDRESS = address(0);
    OraclesLinkProvider internal randomOraclesProvider;

    /**
     * @notice Sets the RandomOraclesProvider address
     * @param _randomOraclesProviderAddress The address of the RandomOraclesProvider token contract
     */
    function setRandomOraclesProvider(address _randomOraclesProviderAddress) internal {
        randomOraclesProvider = OraclesLinkProvider(_randomOraclesProviderAddress);
        emit RandomOraclesProviderAddressSet(_randomOraclesProviderAddress);
    }

    /**
     * @notice Sets the RandomOraclesProvider address for the public
     * network as given by the Pointer contract
     */
    function setPublicRandomOraclesProvider() internal {
        setRandomOraclesProvider(PUBLIC_RANDOM_ORACLES_PROVIDER_ADDRESS);
    }

    /**
     * @notice Retrieves the stored address of the RandomOraclesProvider
     * @return The address of the RandomOraclesProvider token
     */
    function randomOraclesProviderAddress() internal view returns (address) {
        return address(randomOraclesProvider);
    }

    function getSeniorOracleWithJob(uint256 _index, bytes32 _jobType)
        internal
        returns (
            address oracleAddress,
            bytes32 jobId,
            uint256 cost
        )
    {
        (oracleAddress, jobId, cost) = randomOraclesProvider.getSeniorOracleWithJob(_index, _jobType);
        return (oracleAddress, jobId, cost);
    }

    function getMatureOracleWithJob(uint256 _index, bytes32 _jobType)
        internal
        returns (
            address oracleAddress,
            bytes32 jobId,
            uint256 cost
        )
    {
        (oracleAddress, jobId, cost) = randomOraclesProvider.getMatureOracleWithJob(_index, _jobType);
        return (oracleAddress, jobId, cost);
    }

    function getNoviceOracleWithJob(uint256 _index, bytes32 _jobType)
        internal
        returns (
            address oracleAddress,
            bytes32 jobId,
            uint256 cost
        )
    {
        (oracleAddress, jobId, cost) = randomOraclesProvider.getNoviceOracleWithJob(_index, _jobType);
        return (oracleAddress, jobId, cost);
    }

    function getRandomOracleIndices(
        OraclesLink.PerSourceRequirements memory _requirements,
        bytes32 _seed,
        bytes32 _jobType
    )
        private
        returns (
            uint256[] memory seniorOracleIndices,
            uint256[] memory matureOracleIndices,
            uint256[] memory noviceOracleIndices
        )
    {
        // find random senior oracles
        seniorOracleIndices = new uint256[](_requirements.seniorOraclesCount);
        seniorOracleIndices = randomOraclesProvider.getRandomSeniorIndices(_requirements.seniorOraclesCount, _jobType, _seed);

        matureOracleIndices = new uint256[](_requirements.matureOraclesCount);
        if (_requirements.matureOraclesCount > 0) {
            // find random mature oracles
            matureOracleIndices = randomOraclesProvider.getRandomMatureIndices(_requirements.matureOraclesCount, _jobType, _seed);
        }

        noviceOracleIndices = new uint256[](_requirements.noviceOraclesCount);
        if (_requirements.noviceOraclesCount > 0) {
            // find random novice oracles
            noviceOracleIndices = randomOraclesProvider.getRandomNoviceIndices(_requirements.noviceOraclesCount, _jobType, _seed);
        }

        return (seniorOracleIndices, matureOracleIndices, noviceOracleIndices);
    }
}
