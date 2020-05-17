pragma solidity 0.6.8;


/** SPDX-License-Identifier: MIT*/

/**
 * @title Library for common operations
 */
library Utils {
    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
}
