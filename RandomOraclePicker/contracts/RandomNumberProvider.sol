pragma solidity 0.6.8;

import "./RandomModifierHost.sol";


/** SPDX-License-Identifier: MIT*/

/**
 * @title RandomNumberProvider is a contract which provides a random number based on multiple components
 */
contract RandomNumberProvider is RandomModifierHost {
    function getRandomNumberBetween(uint256 _min, uint256 _max) internal view returns (uint256) {}
}
