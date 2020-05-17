pragma solidity 0.6.8;

import "openzeppelin-solidity/contracts/access/Ownable.sol";

import "../OraclesStore/OraclesProviderInterface.sol";
import "./RandomNumbersProvider.sol";
import "./OraclesLinkProvider.sol";


/** SPDX-License-Identifier: MIT*/

/**
 * @title RandomOraclesProvider is a contract which provides randomly picked Chainlink oracles from the OraclesStore for a certain level and job type
 */
contract RandomOraclesProvider is Ownable, OraclesLinkProvider, RandomNumbersProvider {
    event OraclesProviderAddressSet(address storeAddress);
    event RandomIndicesProvided(OraclesProviderInterface.OracleLevel level, bytes32 jobType, uint256[] randomIndices);
    event RandomOracleWithJobProvided(OraclesProviderInterface.OracleLevel level, bytes32 jobType, address oracleAddress, bytes32 jobId);

    address private oraclesProviderAddress;

    constructor(address _oraclesProviderAddress) public {
        oraclesProviderAddress = _oraclesProviderAddress;
    }

    function setOraclesProviderAddress(address _oraclesProviderAddress) external onlyOwner() {
        oraclesProviderAddress = _oraclesProviderAddress;
        emit OraclesProviderAddressSet(_oraclesProviderAddress);
    }

    function getRandomNoviceIndices(
        uint8 _amount,
        bytes32 _jobType,
        bytes32 _seed
    ) external override returns (uint256[] memory) {
        return getRandomOracleIndices(OraclesProviderInterface.OracleLevel.Novice, _amount, _jobType, _seed);
    }

    function getRandomMatureIndices(
        uint8 _amount,
        bytes32 _jobType,
        bytes32 _seed
    ) external override returns (uint256[] memory) {
        return getRandomOracleIndices(OraclesProviderInterface.OracleLevel.Mature, _amount, _jobType, _seed);
    }

    function getRandomSeniorIndices(
        uint8 _amount,
        bytes32 _jobType,
        bytes32 _seed
    ) external override returns (uint256[] memory) {
        return getRandomOracleIndices(OraclesProviderInterface.OracleLevel.Senior, _amount, _jobType, _seed);
    }

    function getNoviceOracleWithJob(uint256 _index, bytes32 _jobType)
        external
        override
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
        override
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
        override
        returns (
            address,
            bytes32,
            uint256
        )
    {
        return getRandomOracleWithJob(OraclesProviderInterface.OracleLevel.Senior, _jobType, _index);
    }

    function getOraclesProvider() private view returns (OraclesProviderInterface oraclesProvider) {
        require(oraclesProviderAddress != address(0), "oraclesProviderAddress must be set");
        return OraclesProviderInterface(oraclesProviderAddress);
    }

    function getRandomOracleIndices(
        OraclesProviderInterface.OracleLevel _level,
        uint8 _amount,
        bytes32 _jobType,
        bytes32 _seed
    ) private returns (uint256[] memory indices) {
        uint8 oracleLevel = getOraclesProvider().castLevelEnumToUint8(_level);

        uint256 oraclesMaxIndex = getOraclesProvider().oraclesCount(oracleLevel, _jobType) - 1;
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
        uint8 oracleLevel = getOraclesProvider().castLevelEnumToUint8(_level);

        (oracleAddress, jobId, cost) = getOraclesProvider().oracleAtIndex(oracleLevel, _jobType, _index);
        emit RandomOracleWithJobProvided(_level, _jobType, oracleAddress, jobId);

        return (oracleAddress, jobId, cost);
    }
}
