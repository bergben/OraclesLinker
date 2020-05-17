pragma solidity 0.6.8;


/** SPDX-License-Identifier: MIT*/

interface OraclesLinkProvider {
    function getRandomNoviceIndices(
        uint8 _amount,
        bytes32 _jobType,
        bytes32 _seed
    ) external returns (uint256[] memory);

    function getRandomMatureIndices(
        uint8 _amount,
        bytes32 _jobType,
        bytes32 _seed
    ) external returns (uint256[] memory);

    function getRandomSeniorIndices(
        uint8 _amount,
        bytes32 _jobType,
        bytes32 _seed
    ) external returns (uint256[] memory);

    function getNoviceOracleWithJob(uint256 _index, bytes32 _jobType)
        external
        returns (
            address,
            bytes32,
            uint256
        );

    function getMatureOracleWithJob(uint256 _index, bytes32 _jobType)
        external
        returns (
            address,
            bytes32,
            uint256
        );

    function getSeniorOracleWithJob(uint256 _index, bytes32 _jobType)
        external
        returns (
            address,
            bytes32,
            uint256
        );
}
