// pragma solidity 0.6.8;

// import "openzeppelin-solidity/contracts/math/SafeMath.sol";
// import "./Utils.sol";


// /** SPDX-License-Identifier: MIT*/

// /**
//  * @title Library for common OraclesLink Request operations
//  */
// library OraclesLink {
//     using SafeMath for uint8;

//     PerSourceRequirements internal immutable SL_MIN;
//     PerSourceRequirements internal immutable SL_LOW;
//     PerSourceRequirements internal immutable SL_DEFAULT;
//     PerSourceRequirements internal immutable SL_CRITICAL;

//     function getSecurityLevelRequirements(SecurityLevel _securityLevel) internal pure returns (PerSourceRequirements storage requirements) {
//         if (_securityLevel == SecurityLevel.Min) {
//             return SL_MIN;
//         }
//         if (_securityLevel == SecurityLevel.Low) {
//             return SL_LOW;
//         }
//         if (_securityLevel == SecurityLevel.Default) {
//             return SL_DEFAULT;
//         } else {
//             return SL_CRITICAL;
//         }
//     }

//     // modifier onlyValidRequirements(OraclesLink.Requirements memory _requirements) {
//     //     // enforce security with senior oracles
//     //     require(_requirements.seniorOraclesCount > 0, "Senior oracles count must be > 0");
//     //     require(_requirements.seniorMinResponses > 0, "Min senior responses must be > 0");
//     //     require(
//     //         _requirements.seniorOraclesCount > (_requirements.matureOraclesCount.add(_requirements.noviceOraclesCount)),
//     //         "Senior oracles count must be > (mature oracles count + novice oracles count)"
//     //     );

//     //     require(_requirements.noviceOraclesCount <= MAX_TOTAL_LEVEL_REQUESTS, "Cannot have more than 21 oracles per level");
//     //     require(_requirements.matureOraclesCount <= MAX_TOTAL_LEVEL_REQUESTS, "Cannot have more than 21 oracles per level");
//     //     require(_requirements.seniorOraclesCount <= MAX_TOTAL_LEVEL_REQUESTS, "Cannot have more than 21 oracles per level");

//     //     _;
//     // }
// }
