pragma solidity 0.6.8;


/** SPDX-License-Identifier: MIT*/

interface OraclesProviderInterface {
    enum OracleLevel {Novice, Mature, Senior}

    /**
     * Used by external RandomOraclePicker
     */
    function oraclesCount(uint8 _level, bytes32 _jobType) external view returns (uint256 count);

    /**
     * Used by external RandomOraclePicker
     */
    function oracleAtIndex(
        uint8 _level,
        bytes32 _jobType,
        uint256 _index
    )
        external
        view
        returns (
            address oracleAddress,
            bytes32 id,
            uint256 cost
        );

    function castUint8LevelToEnum(uint8 _level) external pure returns (OracleLevel);

    function castLevelEnumToUint8(OracleLevel _level) external pure returns (uint8);
}
