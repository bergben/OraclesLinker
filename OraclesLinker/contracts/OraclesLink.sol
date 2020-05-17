pragma solidity 0.6.8;


/** SPDX-License-Identifier: MIT*/

/**
 * @title Library for common OraclesLink Request operations
 */
library OraclesLink {
    struct Base {
        address callbackAddress;
        bytes4 callbackFunctionId;
        Requirements requirements;
    }

    struct Requirements {
        uint8 seniorOraclesCount;
        uint8 seniorMinResponses;
        uint8 matureOraclesCount;
        uint8 matureMinResponses;
        uint8 noviceOraclesCount;
        uint8 noviceMinResponses;
    }

    function setRequirements(
        Base memory self,
        uint8 _seniorOraclesCount,
        uint8 _seniorMinResponses,
        uint8 _matureOraclesCount,
        uint8 _matureMinResponses,
        uint8 _noviceOraclesCount,
        uint8 _noviceMinResponses
    ) internal pure {
        self.requirements = Requirements(
            _seniorOraclesCount,
            _seniorMinResponses,
            _matureOraclesCount,
            _matureMinResponses,
            _noviceOraclesCount,
            _noviceMinResponses
        );
    }
}
