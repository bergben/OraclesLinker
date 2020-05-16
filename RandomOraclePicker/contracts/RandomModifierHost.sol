pragma solidity 0.6.8;


/** SPDX-License-Identifier: MIT*/

/**
 * @title RandomModifierHost is a contract which hosts a random modifier value retrieved by Chainlink VRF that is updated at a given time interval
 */
contract RandomModifierHost {
    uint256 private randomModifier;

    function getRandomNumberBetween() internal view returns (uint256) {
        return randomModifier;
    }
}
