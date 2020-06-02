pragma solidity >=0.5.17;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "./OraclesLinker.sol";


/** SPDX-License-Identifier: MIT*/

/**
 * @title FrostInsuranceSampleContract is an example contract which requests data from
 * the Chainlink network
 * @dev This contract is designed to work on multiple networks, including
 * local test networks
 */
contract FrostInsuranceSampleContract is OraclesLinker, Ownable {
    event InquiryCreated(bytes32 oraclesLinkId, address triggeredBy);
    event InquiryFulfilled(bytes32 oraclesLinkId, int256 answer);

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

    function createInquiry() public returns (bytes32 oraclesLinkId) {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        // contract must hold more than 30 LINK to make sure the oracleLink can be fulfilled (checked in wei)
        require(link.balanceOf(address(this)) > 30000000000000000000, "Not enough LINK available. Must be > 30");

        // user builds oracles link for multiple sources similar to how chainlink buildChainlinkRequest and then sendChainlinkRequestTo works
        OraclesLinkInt256.Request memory oraclesLink = buildOraclesLinkInt256(5, 4);
        oraclesLink.addSource("http://api.openweathermap.org/data/2.5/weather?q=kufstein&units=metric&appid=d693a7d09290d4c3d41b93c81cbb2152", "main.temp", 100);
        oraclesLink.addSource("http://api.weatherstack.com/current?access_key=0675e193645662000b209e2c22325050&query=kufstein&units=m", "current.temperature", 100);
        oraclesLink.addSource("https://api.weatherapi.com/v1/current.json?key=4a1e66a8f2cf4101892202857203105&q=kufstein", "current.temp_c", 100);
        oraclesLink.addSource("https://api.climacell.co/v3/weather/realtime?lat=47.58226&lon=12.16298&unit_system=si&fields=temp&apikey=CFGoZJyDms6BzEnMcRchtCNFGbscQalR", "temp.value", 100);
        oraclesLink.addSource("http://api.weatherunlocked.com/api/current/47.58226,12.16298?app_id=36fd7d92&app_key=5692c15aed836abd136dd8530c34419d", "temp_c", 100);
        oraclesLink.setSecurityLevel(OraclesLink.SecurityLevel.Default);
        oraclesLinkId = sendOraclesLinkInt256(oraclesLink);
        
        emit InquiryCreated(oraclesLinkId, msg.sender);

        return oraclesLinkId;
    }

    /**
     * @notice The fulfill method from OraclesLinks Int256 created by this contract
     * @param _oraclesLinkId The ID that was generated for the OraclesLink
     * @param _answer The answer provided by the aggregated Oracles and sources
     */
    function fulfillOraclesLinkInt256(bytes32 _oraclesLinkId, int256 _answer) internal override {
        emit InquiryFulfilled(_oraclesLinkId, _answer);
        if (_answer < 0) {
            // valid inquiry -> trigger payout
        }
    }

    function ethBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function linkBalance() external view returns (uint256) {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        return link.balanceOf(address(this));
    }

    // withdrawLink allows the owner to withdraw any extra LINK on the contract
    function withdrawLink() public onlyOwner() {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }
}
