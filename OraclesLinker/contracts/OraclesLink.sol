pragma solidity 0.6.8;


/** SPDX-License-Identifier: MIT*/

/**
 * @title Library for common OraclesLink Request operations
 */
library OraclesLink {
    struct PerSourceRequirements {
        uint8 totalMinResponses;
        uint8 seniorOraclesCount;
        uint8 seniorMinResponses;
        uint8 matureOraclesCount;
        uint8 matureMinResponses;
        uint8 noviceOraclesCount;
        uint8 noviceMinResponses;
    }

    // solidity does not support constant structs as of version 0.6.8
    // immutable structs can only be created in non-libraries
    uint8 private constant SL_MIN_totalMinResponses = 1;
    uint8 private constant SL_MIN_seniorOraclesCount = 1;
    uint8 private constant SL_MIN_seniorMinResponses = 1;
    uint8 private constant SL_MIN_matureOraclesCount = 0;
    uint8 private constant SL_MIN_matureMinResponses = 0;
    uint8 private constant SL_MIN_noviceOraclesCount = 0;
    uint8 private constant SL_MIN_noviceMinResponses = 0;

    uint8 private constant SL_LOW_totalMinResponses = 1;
    uint8 private constant SL_LOW_seniorOraclesCount = 1;
    uint8 private constant SL_LOW_seniorMinResponses = 1;
    uint8 private constant SL_LOW_matureOraclesCount = 1;
    uint8 private constant SL_LOW_matureMinResponses = 0;
    uint8 private constant SL_LOW_noviceOraclesCount = 0;
    uint8 private constant SL_LOW_noviceMinResponses = 0;

    uint8 private constant SL_DEFAULT_totalMinResponses = 3;
    uint8 private constant SL_DEFAULT_seniorOraclesCount = 3;
    uint8 private constant SL_DEFAULT_seniorMinResponses = 2;
    uint8 private constant SL_DEFAULT_matureOraclesCount = 1;
    uint8 private constant SL_DEFAULT_matureMinResponses = 0;
    uint8 private constant SL_DEFAULT_noviceOraclesCount = 1;
    uint8 private constant SL_DEFAULT_noviceMinResponses = 0;

    uint8 private constant SL_CRITICAL_totalMinResponses = 5;
    uint8 private constant SL_CRITICAL_seniorOraclesCount = 4;
    uint8 private constant SL_CRITICAL_seniorMinResponses = 3;
    uint8 private constant SL_CRITICAL_matureOraclesCount = 2;
    uint8 private constant SL_CRITICAL_matureMinResponses = 0;
    uint8 private constant SL_CRITICAL_noviceOraclesCount = 1;
    uint8 private constant SL_CRITICAL_noviceMinResponses = 0;

    enum SecurityLevel {Min, Low, Default, Critical}

    function getSecurityLevelRequirements(SecurityLevel _securityLevel)
        internal
        pure
        returns (
            uint8 totalMinResponses,
            uint8 seniorOraclesCount,
            uint8 seniorMinResponses,
            uint8 matureOraclesCount,
            uint8 matureMinResponses,
            uint8 noviceOraclesCount,
            uint8 noviceMinResponses
        )
    {
        if (_securityLevel == SecurityLevel.Min) {
            return (
                SL_MIN_totalMinResponses,
                SL_MIN_seniorOraclesCount,
                SL_MIN_seniorMinResponses,
                SL_MIN_matureOraclesCount,
                SL_MIN_matureMinResponses,
                SL_MIN_noviceOraclesCount,
                SL_MIN_noviceMinResponses
            );
        }
        if (_securityLevel == SecurityLevel.Low) {
            return (
                SL_LOW_totalMinResponses,
                SL_LOW_seniorOraclesCount,
                SL_LOW_seniorMinResponses,
                SL_LOW_matureOraclesCount,
                SL_LOW_matureMinResponses,
                SL_LOW_noviceOraclesCount,
                SL_LOW_noviceMinResponses
            );
        }
        if (_securityLevel == SecurityLevel.Default) {
            return (
                SL_DEFAULT_totalMinResponses,
                SL_DEFAULT_seniorOraclesCount,
                SL_DEFAULT_seniorMinResponses,
                SL_DEFAULT_matureOraclesCount,
                SL_DEFAULT_matureMinResponses,
                SL_DEFAULT_noviceOraclesCount,
                SL_DEFAULT_noviceMinResponses
            );
        } else {
            return (
                SL_CRITICAL_totalMinResponses,
                SL_CRITICAL_seniorOraclesCount,
                SL_CRITICAL_seniorMinResponses,
                SL_CRITICAL_matureOraclesCount,
                SL_CRITICAL_matureMinResponses,
                SL_CRITICAL_noviceOraclesCount,
                SL_CRITICAL_noviceMinResponses
            );
        }
    }
}
