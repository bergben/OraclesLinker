pragma solidity 0.6.8;

import "../../OraclesStore/contracts/OraclesProviderInterface.sol"; // todo replace with npm import;
import "openzeppelin-solidity/contracts/access/Ownable.sol";

import "./RandomNumbersProvider.sol";


/** SPDX-License-Identifier: MIT*/

/**
 * @title RandomOraclesProvider is a contract which provides randomly picked Chainlink oracles from the OraclesStore for a certain level and job type
 */
contract RandomOraclesProvider is Ownable, RandomNumbersProvider {
    event OraclesStoreAddressSet(address storeAddress);
    event RandomIndicesProvided(OraclesProviderInterface.OracleLevel level, bytes32 jobType, uint256[] randomIndices);
    event RandomOracleWithJobProvided(OraclesProviderInterface.OracleLevel level, bytes32 jobType, address oracleAddress, bytes32 jobId);

    address private oraclesStoreAddress;
    OraclesProviderInterface private oraclesProvider;

    constructor(address _oraclesStoreAddress) public {
        oraclesStoreAddress = _oraclesStoreAddress;
    }

    function setOraclesStoreAddress(address _oraclesStoreAddress) external onlyOwner() {
        oraclesStoreAddress = _oraclesStoreAddress;
        emit OraclesStoreAddressSet(_oraclesStoreAddress);
    }

    function getRandomNoviceIndices(
        uint8 _amount,
        bytes32 _jobType,
        bytes32 _seed
    ) external returns (uint256[] memory) {
        return getRandomOracleIndices(OraclesProviderInterface.OracleLevel.Novice, _amount, _jobType, _seed);
    }

    function getRandomMatureIndices(
        uint8 _amount,
        bytes32 _jobType,
        bytes32 _seed
    ) external returns (uint256[] memory) {
        return getRandomOracleIndices(OraclesProviderInterface.OracleLevel.Mature, _amount, _jobType, _seed);
    }

    function getRandomSeniorIndices(
        uint8 _amount,
        bytes32 _jobType,
        bytes32 _seed
    ) external returns (uint256[] memory) {
        return getRandomOracleIndices(OraclesProviderInterface.OracleLevel.Senior, _amount, _jobType, _seed);
    }

    function getNoviceOracleWithJob(uint256 _index, bytes32 _jobType)
        external
        returns (
            address,
            bytes32,
            uint256
        )
    {
        return getRandomOracleWithJob(OraclesProviderInterface.OracleLevel.Novice, _jobType, _index);
    }

    function getMatureOracleWithJob(uint256 _index, bytes32 _jobType)
        external
        returns (
            address,
            bytes32,
            uint256
        )
    {
        return getRandomOracleWithJob(OraclesProviderInterface.OracleLevel.Mature, _jobType, _index);
    }

    function getSeniorOracleWithJob(uint256 _index, bytes32 _jobType)
        external
        returns (
            address,
            bytes32,
            uint256
        )
    {
        return getRandomOracleWithJob(OraclesProviderInterface.OracleLevel.Senior, _jobType, _index);
    }

    function getRandomOracleIndices(
        OraclesProviderInterface.OracleLevel _level,
        uint8 _amount,
        bytes32 _jobType,
        bytes32 _seed
    ) private returns (uint256[] memory indices) {
        uint8 oracleLevel = oraclesProvider.castLevelEnumToUint8(_level);

        uint256 oraclesMaxIndex = oraclesProvider.oraclesCount(oracleLevel, _jobType) - 1;
        require(oraclesMaxIndex >= 0, "No oracle available");

        indices = getRandomNumbersBetween(_amount, _seed, 0, oraclesMaxIndex);

        emit RandomIndicesProvided(_level, _jobType, indices);

        return indices;
    }

    function getRandomOracleWithJob(
        OraclesProviderInterface.OracleLevel _level,
        bytes32 _jobType,
        uint256 _index
    )
        private
        returns (
            address oracleAddress,
            bytes32 jobId,
            uint256 cost
        )
    {
        uint8 oracleLevel = oraclesProvider.castLevelEnumToUint8(_level);

        (oracleAddress, jobId, cost) = oraclesProvider.oracleAtIndex(oracleLevel, _jobType, _index);
        emit RandomOracleWithJobProvided(_level, _jobType, oracleAddress, jobId);

        return (oracleAddress, jobId, cost);
    }
}
