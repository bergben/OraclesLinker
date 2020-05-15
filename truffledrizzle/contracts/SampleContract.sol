pragma solidity >=0.5.17;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./OraclesLinker.sol"; // todo replace with npm


/**
 * @title SampleContract is an example contract which requests data from
 * the Chainlink network
 * @dev This contract is designed to work on multiple networks, including
 * local test networks
 */
contract SampleContract is OraclesLinker, Ownable {
    function triggerOraclesLink(uint256 _payment) public onlyOwner returns (bytes32 oraclesLinkId) {
        // user builds request for multiple sources similar to how chainlink buildChainlinkRequest and then sendChainlinkRequestTo works
        OraclesLink.Int256 memory oraclesLink = buildInt256Link(address(this), this.fulfill.selector);
        oraclesLink.addSource("https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD", "USD", 100);
        oraclesLink.addSource("https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD", "USD", 100);
        oraclesLink.addSource("https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD", "USD", 100);
        oraclesLink.setAggregationMethod(AggregationMethod.Median);
        oraclesLinkId = oraclesLink.sendRequest(_payment);
        return oraclesLinkId;
    }

    uint256 public data;

    /**
     * @notice Deploy the contract with a specified address for the LINK
     * and Oracle contract addresses
     * @dev Sets the storage for the specified addresses
     * @param _link The address of the LINK token contract
     */
    constructor(address _link) public {
        if (_link == address(0)) {
            setPublicChainlinkToken();
        } else {
            setChainlinkToken(_link);
        }
    }

    /**
     * @notice Returns the address of the LINK token
     * @dev This is the public implementation for chainlinkTokenAddress, which is
     * an internal method of the ChainlinkClient contract
     */
    function getChainlinkToken() public view returns (address) {
        return chainlinkTokenAddress();
    }

    /**
     * @notice Creates a request to the specified Oracle contract address
     * @dev This function ignores the stored Oracle contract address and
     * will instead send the request to the address specified
     * @param _oracle The Oracle contract address to send the request to
     * @param _jobId The bytes32 JobID to be executed
     * @param _url The URL to fetch data from
     * @param _path The dot-delimited path to parse of the response
     * @param _times The number to multiply the result by
     */
    function createRequestTo(
        address _oracle,
        bytes32 _jobId,
        uint256 _payment,
        string memory _url,
        string memory _path,
        int256 _times
    ) public onlyOwner returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(_jobId, address(this), this.fulfill.selector);
        req.add("url", _url);
        req.add("path", _path);
        req.addInt("times", _times);
        requestId = sendChainlinkRequestTo(_oracle, req, _payment);
    }

    /**
     * @notice The fulfill method from requests created by this contract
     * @dev The recordChainlinkFulfillment protects this function from being called
     * by anyone other than the oracle address that the request was sent to
     * @param _requestId The ID that was generated for the request
     * @param _data The answer provided by the oracle
     */
    function fulfill(bytes32 _requestId, uint256 _data) public recordChainlinkFulfillment(_requestId) {
        data = _data;
    }

    /**
     * @notice Allows the owner to withdraw any LINK balance on the contract
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }

    /**
     * @notice Call this method if no response is received within 5 minutes
     * @param _requestId The ID that was generated for the request to cancel
     * @param _payment The payment specified for the request to cancel
     * @param _callbackFunctionId The bytes4 callback function ID specified for
     * the request to cancel
     * @param _expiration The expiration generated for the request to cancel
     */
    function cancelRequest(
        bytes32 _requestId,
        uint256 _payment,
        bytes4 _callbackFunctionId,
        uint256 _expiration
    ) public onlyOwner {
        cancelChainlinkRequest(_requestId, _payment, _callbackFunctionId, _expiration);
    }
}
