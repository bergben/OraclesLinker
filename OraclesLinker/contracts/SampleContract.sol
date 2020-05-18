pragma solidity >=0.5.17;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "./OraclesLinker.sol"; // todo replace with npm


/** SPDX-License-Identifier: MIT*/

/**
 * @title SampleContract is an example contract which requests data from
 * the Chainlink network
 * @dev This contract is designed to work on multiple networks, including
 * local test networks
 */
contract SampleContract is OraclesLinker, Ownable {
    event OraclesLinkFulfilled(bytes32 oraclesLinkId, int256 answer);

    constructor(address _randomOraclesProviderAddress, address _linkAddress) public {
        // Set the address for the RandomOraclesProvider token for the network.
        if (_randomOraclesProviderAddress == address(0)) {
            // Useful for deploying to public networks.
            setPublicRandomOraclesProvider();
        } else {
            // Useful if you're deploying to a local network.
            setRandomOraclesProvider(_randomOraclesProviderAddress);
        }

        // Set the address for the LINK token for the network.
        if (_linkAddress == address(0)) {
            // Useful for deploying to public networks.
            setPublicChainlinkToken();
        } else {
            // Useful if you're deploying to a local network.
            setChainlinkToken(_linkAddress);
        }
    }

    function triggerOraclesLink(uint256 _payment) public onlyOwner returns (bytes32 oraclesLinkId) {
        // user builds oracles link for multiple sources similar to how chainlink buildChainlinkRequest and then sendChainlinkRequestTo works
        OraclesLinkInt256.Request memory oraclesLink = buildOraclesLinkInt256(3, 2);
        oraclesLink.addSource("https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD", "USD", 100);
        oraclesLink.addSource("https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD", "USD", 100);
        oraclesLink.addSource("https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD", "USD", 100);
        oraclesLink.setAggregationMethod(OraclesLinkInt256.AggregationMethod.Median);
        oraclesLinkId = sendOraclesLinkInt256(oraclesLink, _payment);
        return oraclesLinkId;
    }

    /**
     * @notice The fulfill method from OraclesLinks Int256 created by this contract
     * @param _oraclesLinkId The ID that was generated for the OraclesLink
     * @param _answer The answer provided by the aggregated Oracles and sources
     */
    function fulfillOraclesLinkInt256(bytes32 _oraclesLinkId, int256 _answer) internal override {
        emit OraclesLinkFulfilled(_oraclesLinkId, _answer);
    }

    // withdrawLink allows the owner to withdraw any extra LINK on the contract
    function withdrawLink() public onlyOwner() {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }
}
