pragma solidity 0.6.8;

import "../../OraclesStore/contracts/OraclesProviderInterface.sol"; // todo replace with npm import;
import "openzeppelin-solidity/contracts/access/Ownable.sol";

import "./RandomNumberProvider.sol";


/** SPDX-License-Identifier: MIT*/

/**
 * @title RandomOraclePicker is a contract which automatically picks a Chainlink oracle from the OraclesStore for a certain level and job type at random
 */
contract RandomOraclePicker is Ownable, RandomNumberProvider {
    event OraclesStoreAddressSet(address storeAddress);
    event RandomOraclePicked(OraclesProviderInterface.OracleLevel level, bytes32 jobType, address oracleAddress, bytes32 jobId);

    address private oraclesStoreAddress;
    OraclesProviderInterface private oraclesProvider;
    uint256 private random;

    constructor(address _oraclesStoreAddress) public {
        oraclesStoreAddress = _oraclesStoreAddress;
    }

    function setOraclesStoreAddress(address _oraclesStoreAddress) external onlyOwner() {
        oraclesStoreAddress = _oraclesStoreAddress;
        emit OraclesStoreAddressSet(_oraclesStoreAddress);
    }

    function pickRandomNoviceOracleWithJob(bytes32 _jobType)
        external
        returns (
            address oracleAddress,
            bytes32 jobId,
            uint256 cost
        )
    {
        return pickRandomOracleWithJob(OraclesProviderInterface.OracleLevel.Novice, _jobType);
    }

    function pickRandomMatureOracleWithJob(bytes32 _jobType)
        external
        returns (
            address oracleAddress,
            bytes32 jobId,
            uint256 cost
        )
    {
        return pickRandomOracleWithJob(OraclesProviderInterface.OracleLevel.Mature, _jobType);
    }

    function pickRandomSeniorOracleWithJob(bytes32 _jobType)
        external
        returns (
            address oracleAddress,
            bytes32 jobId,
            uint256 cost
        )
    {
        return pickRandomOracleWithJob(OraclesProviderInterface.OracleLevel.Senior, _jobType);
    }

    function pickRandomOracleWithJob(OraclesProviderInterface.OracleLevel _level, bytes32 _jobType)
        private
        returns (
            address,
            bytes32,
            uint256
        )
    {
        uint8 oracleLevel = oraclesProvider.castLevelEnumToUint8(_level);

        uint256 oraclesMaxIndex = oraclesProvider.oraclesCount(oracleLevel, _jobType) - 1;
        require(oraclesMaxIndex >= 0, "No oracle available");

        uint256 randomIndex = getRandomNumberBetween(0, oraclesMaxIndex);

        (address oracleAddress, bytes32 jobId, uint256 cost) = oraclesProvider.oracleAtIndex(oracleLevel, _jobType, randomIndex);
        emit RandomOraclePicked(_level, _jobType, oracleAddress, jobId);

        return (oracleAddress, jobId, cost);
    }
}
