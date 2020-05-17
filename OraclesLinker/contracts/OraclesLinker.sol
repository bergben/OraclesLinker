pragma solidity 0.6.8;

import "oracles-link-provider/contracts/RandomOraclesProvider/OraclesLinkProvider.sol";
import "./OraclesLinkInt256.sol";


/** SPDX-License-Identifier: MIT*/

/**
 * @title OraclesLinker is a contract which creates requests to multiple chainlink oracles picked at random by the RandomOraclesProvider
 */
contract OraclesLinker {
    using OraclesLinkInt256 for OraclesLinkInt256.Request;
    event RandomOraclesProviderAddressSet(address randomOraclesProviderAddress);
    address private randomOraclesProviderAddress;
    address private PUBLIC_RANDOM_ORACLES_PROVIDER_ADDRESS = address(0);
    OraclesLinkProvider randomOraclesProvider;

    constructor(address _randomOraclesProviderAddress) public {
        // Set the address for the RandomOraclesProvider token for the network.
        if (_randomOraclesProviderAddress == address(0)) {
            // Useful for deploying to public networks.
            setPublicRandomOraclesProvider();
        } else {
            // Useful if you're deploying to a local network.
            setRandomOraclesProvider(_randomOraclesProviderAddress);
        }
    }

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
        return address(_randomOraclesProviderAddress);
    }

    function oraclesLinkInt256(address _callbackAddress, bytes4 _callbackFunctionSignature)
        internal
        pure
        returns (OraclesLinkInt256.Request memory)
    {
        OraclesLinkInt256.Request memory req;
        req.initialize(_callbackAddress, _callbackFunctionSignature);
        req.onSendCallback = onInt256Send(req);
        return;
    }

    function sendInt256(OraclesLinkInt256.Request memory req, uint256 _payment) internal returns (bytes32 oraclesLinkId) {}
}
