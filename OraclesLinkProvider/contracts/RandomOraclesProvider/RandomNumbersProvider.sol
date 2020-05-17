pragma solidity 0.6.8;


/** SPDX-License-Identifier: MIT*/

/**
 * @title RandomNumbersProvider is a contract which provides a random number based on multiple factors
 */
contract RandomNumbersProvider {
    uint256 globalNonce;

    function getRandomNumbersBetween(
        uint8 _amount,
        bytes32 _seed,
        uint256 _min,
        uint256 _max
    ) internal returns (uint256[] memory randomNumbers) {
        require(_max > _min, "max must be > min");

        bytes32 seed = keccak256(abi.encode(block.timestamp, _seed, _min, _max, _amount));
        randomNumbers = new uint256[](_amount);

        for (uint8 i = 0; i < _amount; i++) {
            uint256 randomNumber = getRandomNumberBetween(i, seed, _min, _max);

            // make sure numbers are unique
            while (isNumberInArray(randomNumber, randomNumbers)) {
                randomNumber++;
                // make sure number is not out of bounds
                if (randomNumber > _max) {
                    randomNumber = _min;
                }
            }
            randomNumbers[i] = randomNumber;
        }

        return randomNumbers;
    }

    function isNumberInArray(uint256 number, uint256[] memory array) private pure returns (bool) {
        for (uint8 i = 0; i < array.length; i++) {
            if (array[i] == number) {
                return true;
            }
        }
        return false;
    }

    function getRandomNumberBetween(
        uint8 _index,
        bytes32 _seed,
        uint256 _min,
        uint256 _max
    ) private returns (uint256 randomNumber) {
        bytes32 randomHash = keccak256(abi.encode(_seed, globalNonce, _index));
        randomNumber = uint256(randomHash);

        // let it overflow, it's ok
        globalNonce++;

        // use modulo to make randomNumber fit to max bound
        // then add _min to fit min bound
        return (randomNumber % (_max + 1)) + _min;
    }
}
