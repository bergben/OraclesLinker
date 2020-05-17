pragma solidity 0.6.8;

import "oracles-link-provider/contracts/RandomOraclesProvider/OraclesLinkProvider.sol";


/** SPDX-License-Identifier: MIT*/

/**
 * @title RandomOraclesProviderHost is a contract who hosts the connection to the RandomOraclesProvider
 */
contract RandomOraclesProviderHost {
    event RandomOraclesProviderAddressSet(address randomOraclesProviderAddress);

    address private PUBLIC_RANDOM_ORACLES_PROVIDER_ADDRESS = address(0);
    OraclesLinkProvider internal randomOraclesProvider;

    /**
     * @notice Sets the RandomOraclesProvider address
     * @param _randomOraclesProviderAddress The address of the RandomOraclesProvider token contract
     */
    function setRandomOraclesProvider(address _randomOraclesProviderAddress) internal {
        randomOraclesProvider = OraclesLinkProvider(_randomOraclesProviderAddress);
        emit RandomOraclesProviderAddressSet(_randomOraclesProviderAddress);
    }

    /**
     * @notice Sets the RandomOraclesProvider address for the public
     * network as given by the Pointer contract
     */
    function setPublicRandomOraclesProvider() internal {
        setRandomOraclesProvider(PUBLIC_RANDOM_ORACLES_PROVIDER_ADDRESS);
    }

    /**
     * @notice Retrieves the stored address of the RandomOraclesProvider
     * @return The address of the RandomOraclesProvider token
     */
    function randomOraclesProviderAddress() internal view returns (address) {
        return address(randomOraclesProvider);
    }
}
