pragma solidity >=0.5.17;

import "@chainlink/contracts/src/v0.5/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.5/LinkTokenReceiver.sol";
import "@chainlink/contracts/src/v0.5/Median.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./OraclesLink.sol";
import "./OraclesSelector.sol";
import "./OraclesLinkAggregator.sol";


/**
 * @title OraclesLinker is a contract that builds on-chain service agreements
 * using the current architecture of 1 request to 1 oracle contract.
 * @dev This contract accepts requests as service agreement IDs and loops over
 * the corresponding list of oracles to create distinct requests to each one.
 */
contract OraclesLinker is ChainlinkClient, Ownable, LinkTokenReceiver, OraclesSelector, OraclesLinkAggregator {
    using SafeMath for uint256;

    uint256 private constant MAX_TOTAL_LEVEL_REQUESTS = 21;

    function getInt256Link(
        string memory _url,
        string memory _path,
        uint256 memory times,
        OraclesLink.Requirements memory _requirements
    ) internal onlyLINK checkCallbackAddress(_callbackAddress) onlyValidRequirements(_requirements) returns (bytes32 oraclesLinkId) {
        // Todo: Payment with transferAndCall compatibility, implement similar to how in PreCoordinator and adapt from LinkTokenReceiver.
        // select random oracle for requirements

        // loop over the selection method and aggregate the oracles in arrays
        address[] oracleAddresses;
        bytes32[] jobIds;
        uint256[] payments;
        uint256[] alreadySelected;
        uint256 totalOracles = 0;

        // select senior nodes
        for (uint256 i = 0; i < _requirements.seniorOraclesCount; i++) {
            (oracleAddresses[totalOracles], jobIds[totalOracles], payments[totalOracles], alreadySelected[i]) = OraclesSelector.select(
                OraclesLink.JobType.HttpGetInt256,
                OraclesLink.OraclesLevel.Senior,
                totalOracles,
                alreadySelected
            );
            totalOracles++;
        }
        delete alreadySelected;

        // select mature nodes
        for (uint256 i = 0; i < _requirements.matureOraclesCount; i++) {
            (oracleAddresses[totalOracles], jobIds[totalOracles], payments[totalOracles], alreadySelected[i]) = OraclesSelector.select(
                OraclesLink.JobType.HttpGetInt256,
                OraclesLink.OraclesLevel.Mature,
                totalOracles,
                alreadySelected
            );
            totalOracles++;
        }
        delete alreadySelected;

        // select novice nodes
        for (uint256 i = 0; i < _requirements.noviceOraclesCount; i++) {
            (oracleAddresses[totalOracles], jobIds[totalOracles], payments[totalOracles], alreadySelected[i]) = OraclesSelector.select(
                OraclesLink.JobType.HttpGetInt256,
                OraclesLink.OraclesLevel.Novice,
                totalOracles,
                alreadySelected
            );
            totalOracles++;
        }
        delete alreadySelected;

        // send out requests
        createRequests();
        // return oraclesLinkId? (or requestIds?)
        // todo add requirement -> there have to be this many oracles available for a certain jobType / level
    }

    function createOraclesLinkRequirements(
        uint256 _noviceOraclesCount,
        uint256 _noviceMinResponses,
        uint256 _matureOraclesCount,
        uint256 _matureMinResponses,
        uint256 _seniorOraclesCount,
        uint256 _seniorMinResponses
    )
        internal
        onlyValidRequirements(
            OraclesLink.Requirements(
                _noviceOraclesCount,
                _noviceMinResponses,
                _matureOraclesCount,
                _matureMinResponses,
                _seniorOraclesCount,
                _seniorMinResponses
            )
        )
        returns (OraclesLink.Requirements memory requirements)
    {
        return
            OraclesLink.Requirements(
                _noviceOraclesCount,
                _noviceMinResponses,
                _matureOraclesCount,
                _matureMinResponses,
                _seniorOraclesCount,
                _seniorMinResponses
            );
    }

    modifier onlyValidRequirements(OraclesLink.Requirements memory _requirements) {
        // enforce security with senior oracles
        require(_requirements.seniorOraclesCount > 0, "Senior oracles count must be > 0");
        require(_requirements.seniorMinResponses > 0, "Min senior responses must be > 0");
        require(
            _requirements.seniorOraclesCount > (matureOraclesCount.add(noviceOraclesCount)),
            "Senior oracles count must be > (mature oracles count + novice oracles count)"
        );

        require(_requirements.noviceOraclesCount <= MAX_ORACLE_COUNT, "Cannot have more than 21 oracles per level");
        require(_requirements.matureOraclesCount <= MAX_ORACLE_COUNT, "Cannot have more than 21 oracles per level");
        require(_requirements.seniorOraclesCount <= MAX_ORACLE_COUNT, "Cannot have more than 21 oracles per level");

        _;
    }

    // ----------------------------------------------------------------------------
    //
    // from PreCoordaintor, Todo:
    uint256 private globalNonce;

    struct Requester {
        bytes4 callbackFunctionId;
        address sender;
        address callbackAddress;
        int256[] responses;
    }

    // Service Agreement ID => ServiceAgreement
    mapping(bytes32 => ServiceAgreement) internal serviceAgreements;
    // Local Request ID => Service Agreement ID
    mapping(bytes32 => bytes32) internal serviceAgreementRequests;
    // Requester's Request ID => Requester
    mapping(bytes32 => Requester) internal requesters;
    // Local Request ID => Requester's Request ID
    mapping(bytes32 => bytes32) internal requests;

    event NewServiceAgreement(bytes32 indexed saId, uint256 payment, uint256 minresponses);
    event ServiceAgreementRequested(bytes32 indexed saId, bytes32 indexed requestId, uint256 payment);
    event ServiceAgreementResponseReceived(bytes32 indexed saId, bytes32 indexed requestId, address indexed oracle, int256 answer);
    event ServiceAgreementAnswerUpdated(bytes32 indexed saId, bytes32 indexed requestId, int256 answer);
    event ServiceAgreementDeleted(bytes32 indexed saId);

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
     * @notice Creates the Chainlink request
     * @dev Stores the hash of the params as the on-chain commitment for the request.
     * Emits OracleRequest event for the Chainlink node to detect.
     * @param _sender The sender of the request
     * @param _payment The amount of payment given (specified in wei)
     * @param _saId The Job Specification ID
     * @param _callbackAddress The callback address for the response
     * @param _callbackFunctionId The callback function ID for the response
     * @param _nonce The nonce sent by the requester
     * @param _data The CBOR payload of the request
     */
    function oracleRequest(
        address _sender,
        uint256 _payment,
        bytes32 _saId,
        address _callbackAddress,
        bytes4 _callbackFunctionId,
        uint256 _nonce,
        uint256,
        bytes calldata _data
    ) external onlyLINK checkCallbackAddress(_callbackAddress) {
        uint256 totalPayment = serviceAgreements[_saId].totalPayment;
        // this revert message does not bubble up
        require(_payment >= totalPayment, "Insufficient payment");
        bytes32 callbackRequestId = keccak256(abi.encodePacked(_sender, _nonce));
        require(requesters[callbackRequestId].sender == address(0), "Nonce already in-use");
        requesters[callbackRequestId].callbackFunctionId = _callbackFunctionId;
        requesters[callbackRequestId].callbackAddress = _callbackAddress;
        requesters[callbackRequestId].sender = _sender;
        createRequests(_saId, callbackRequestId, _data);
        if (_payment > totalPayment) {
            uint256 overage = _payment.sub(totalPayment);
            LinkTokenInterface _link = LinkTokenInterface(chainlinkTokenAddress());
            assert(_link.transfer(_sender, overage));
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
     * @dev Creates Chainlink requests to each oracle in the service agreement with the
     * same data payload supplied by the requester
     * @param _saId The service agreement ID
     * @param _incomingRequestId The requester-supplied request ID
     * @param _data The data payload (request parameters) to send to each oracle
     */
    function createRequests(
        bytes32 _saId,
        bytes32 _incomingRequestId,
        bytes memory _data
    ) private {
        ServiceAgreement memory sa = serviceAgreements[_saId];
        require(sa.minResponses > 0, "Invalid service agreement");
        Chainlink.Request memory request;
        bytes32 outgoingRequestId;
        serviceAgreements[_saId].activeRequests = serviceAgreements[_saId].activeRequests.add(1);
        emit ServiceAgreementRequested(_saId, _incomingRequestId, sa.totalPayment);
        for (uint256 i = 0; i < sa.oracles.length; i++) {
            request = buildChainlinkRequest(sa.jobIds[i], address(this), this.chainlinkCallback.selector);
            request.setBuffer(_data);
            outgoingRequestId = sendChainlinkRequestTo(sa.oracles[i], request, sa.payments[i]);
            requests[outgoingRequestId] = _incomingRequestId;
            serviceAgreementRequests[outgoingRequestId] = _saId;
        }
    }

    /**
     * @notice The fulfill method from requests created by this contract
     * @dev The recordChainlinkFulfillment protects this function from being called
     * by anyone other than the oracle address that the request was sent to
     * @param _requestId The ID that was generated for the request
     * @param _data The answer provided by the oracle
     */
    function chainlinkCallback(bytes32 _requestId, int256 _data) external recordChainlinkFulfillment(_requestId) returns (bool) {
        uint256 minResponses = serviceAgreements[serviceAgreementRequests[_requestId]].minResponses;
        bytes32 cbRequestId = requests[_requestId];
        bytes32 saId = serviceAgreementRequests[_requestId];
        delete requests[_requestId];
        delete serviceAgreementRequests[_requestId];
        emit ServiceAgreementResponseReceived(saId, cbRequestId, msg.sender, _data);
        if (requesters[cbRequestId].responses.push(_data) == minResponses) {
            serviceAgreements[saId].activeRequests = serviceAgreements[saId].activeRequests.sub(1);
            Requester memory req = requesters[cbRequestId];
            delete requesters[cbRequestId];
            int256 result = Median.calculate(req.responses);
            emit ServiceAgreementAnswerUpdated(saId, cbRequestId, result);
            /* solium-disable-next-line */
            (bool success, ) = req.callbackAddress.call(abi.encodeWithSelector(req.callbackFunctionId, cbRequestId, result));
            return success;
        }
        return true;
    }

    /**
     * @notice Allows the owner to withdraw any LINK balance on the contract
     * @dev The only valid case for there to be remaining LINK on this contract
     * is if a user accidentally sent LINK directly to this contract's address.
     */
    function withdrawLink() external onlyOwner {
        LinkTokenInterface _link = LinkTokenInterface(chainlinkTokenAddress());
        require(_link.transfer(msg.sender, _link.balanceOf(address(this))), "Unable to transfer");
    }

    /**
     * @notice Call this method if no response is received within 5 minutes
     * @param _requestId The ID that was generated for the request to cancel
     * @param _payment The payment specified for the request to cancel
     * @param _callbackFunctionId The bytes4 callback function ID specified for
     * the request to cancel
     * @param _expiration The expiration generated for the request to cancel
     */
    function cancelOracleRequest(
        bytes32 _requestId,
        uint256 _payment,
        bytes4 _callbackFunctionId,
        uint256 _expiration
    ) external {
        bytes32 cbRequestId = requests[_requestId];
        delete requests[_requestId];
        delete serviceAgreementRequests[_requestId];
        Requester memory req = requesters[cbRequestId];
        require(req.sender == msg.sender, "Only requester can cancel");
        delete requesters[cbRequestId];
        cancelChainlinkRequest(_requestId, _payment, _callbackFunctionId, _expiration);
        LinkTokenInterface _link = LinkTokenInterface(chainlinkTokenAddress());
        require(_link.transfer(req.sender, _payment), "Unable to transfer");
    }

    /**
     * @dev Reverts if the Service Agreement has active callbacks
     * @param _saId The service agreement ID
     */
    modifier whenNotActive(bytes32 _saId) {
        require(serviceAgreements[_saId].activeRequests == 0, "Cannot delete while active");
        _;
    }

    /**
     * @dev Reverts if the callback address is the LINK token
     * @param _to The callback address
     */
    modifier checkCallbackAddress(address _to) {
        require(_to != chainlinkTokenAddress(), "Cannot callback to LINK");
        _;
    }
}
