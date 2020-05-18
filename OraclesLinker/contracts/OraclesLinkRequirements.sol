pragma solidity 0.6.8;

import "./OraclesLink.sol";


/** SPDX-License-Identifier: MIT*/

/**
 * @title Library for OraclesLink Requirements common to all OracleLinks
 */
library OraclesLinkRequirements {
    struct Requirements {
        OraclesLink.PerSourceRequirements perSourceRequirements;
    }

    function setSecurityLevel(Base memory self, OraclesLink.SecurityLevel _securityLevel) internal pure {
        (
            uint8 totalMinResponses,
            uint8 seniorOraclesCount,
            uint8 seniorMinResponses,
            uint8 matureOraclesCount,
            uint8 matureMinResponses,
            uint8 noviceOraclesCount,
            uint8 noviceMinResponses
        ) = OraclesLink.getSecurityLevelRequirements(_securityLevel);
        OraclesLinkBase.setPerSourceRequirements(
            self,
            totalMinResponses,
            seniorOraclesCount,
            seniorMinResponses,
            matureOraclesCount,
            matureMinResponses,
            noviceOraclesCount,
            noviceMinResponses
        );
    }

    function setPerSourceRequirements(
        Base memory self,
        uint8 _totalMinResponses,
        uint8 _seniorOraclesCount,
        uint8 _seniorMinResponses,
        uint8 _matureOraclesCount,
        uint8 _matureMinResponses,
        uint8 _noviceOraclesCount,
        uint8 _noviceMinResponses
    ) internal pure {
        self.perSourceRequirements = OraclesLink.PerSourceRequirements(
            _totalMinResponses,
            _seniorOraclesCount,
            _seniorMinResponses,
            _matureOraclesCount,
            _matureMinResponses,
            _noviceOraclesCount,
            _noviceMinResponses
        );
    }
}
