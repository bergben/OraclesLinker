pragma solidity >=0.5.17;

import "./Whitelisted.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";


/**
 * @title WhitelistedProposalsCoordinator is a contract which handles proposals for oracle changes in rounds from whitelisted externals
 */
contract WhitelistedProposalsCoordinator is Whitelisted {
    using SafeMath for uint256;
    enum ProposalOperation {AddOracle, RemoveOracle, AddJob, RemoveJob}

    uint8 internal minProposalSupporters;
    address[] private startRoundProposals;
    address[] private endRoundProposals;
    bool private isRoundRunning;
    uint256 private lastRoundStartTimestamp;
    uint8 private minPassedMinutesToForceStop;

    struct AddOracleProposal {
        address oracleAddress;
        uint8 level;
    }

    struct AddJobProposal {
        address oracleAddress;
        bytes32 id;
        bytes32 jobType;
        uint256 cost;
    }

    struct RemoveJobProposal {
        address oracleAddress;
        bytes32 id;
    }

    // array of hashes for proposals that can be iterated over
    bytes32[] internal proposalHashes;

    // mapping proposal hash => array of proposal sender addresses
    mapping(bytes32 => address[]) internal proposalSupporters;
    // mapping for checking if a certain proposal Hash exists
    mapping(bytes32 => bool) internal proposalExists;
    // mapping proposal hash => Proposal Operation
    mapping(bytes32 => ProposalOperation) internal proposalOperations;

    // mapping proposal hash => respective Proposal data
    mapping(bytes32 => AddOracleProposal) internal addOracleProposals;
    mapping(bytes32 => address) internal removeOracleProposals;
    mapping(bytes32 => AddJobProposal) internal addJobProposals;
    mapping(bytes32 => RemoveJobProposal) internal removeJobProposals;

    /**
     * overriden from parent contract
     */
    function onRoundEnd() internal;

    function setMinProposalSupporters(uint8 _min) external onlyOwner {
        minProposalSupporters = _min;
    }

    function setMinPassedMinutesToForceStop(uint8 _min) external onlyOwner {
        minPassedMinutesToForceStop = _min;
    }

    function proposeAddOracle(address _oracleAddress, uint8 _level) external onlyWhitelisted() roundRunning() {
        bytes32 proposalHash = keccak256(abi.encode(ProposalOperation.AddOracle, _oracleAddress, _level));
        proposalSupporters[proposalHash].push(msg.sender);
        if (!proposalExists[proposalHash]) {
            // all this data has to match for each proposal so it's only added once
            proposalExists[proposalHash] = true;
            proposalHashes.push(proposalHash);
            proposalOperations[proposalHash] = ProposalOperation.AddOracle;
            addOracleProposals[proposalHash] = AddOracleProposal(_oracleAddress, _level);
        }
    }

    function proposeRemoveOracle(address _oracleAddress) external onlyWhitelisted() roundRunning() {
        bytes32 proposalHash = keccak256(abi.encode(ProposalOperation.RemoveOracle, _oracleAddress));
        proposalSupporters[proposalHash].push(msg.sender);
        if (!proposalExists[proposalHash]) {
            // all this data has to match for each proposal so it's only added once
            proposalExists[proposalHash] = true;
            proposalHashes.push(proposalHash);
            proposalOperations[proposalHash] = ProposalOperation.RemoveOracle;
            removeOracleProposals[proposalHash] = _oracleAddress;
        }
    }

    function proposeAddJob(
        address _oracleAddress,
        bytes32 _id,
        bytes32 _jobType,
        uint256 _cost
    ) external onlyWhitelisted() roundRunning() {
        bytes32 proposalHash = keccak256(abi.encode(ProposalOperation.AddJob, _oracleAddress, _id, _jobType, _cost));
        proposalSupporters[proposalHash].push(msg.sender);
        if (!proposalExists[proposalHash]) {
            // all this data has to match for each proposal so it's only added once
            proposalExists[proposalHash] = true;
            proposalHashes.push(proposalHash);
            proposalOperations[proposalHash] = ProposalOperation.AddJob;
            addJobProposals[proposalHash] = AddJobProposal(_oracleAddress, _id, _jobType, _cost);
        }
    }

    function proposeRemoveJob(address _oracleAddress, bytes32 _id) external onlyWhitelisted() roundRunning() {
        bytes32 proposalHash = keccak256(abi.encode(ProposalOperation.RemoveJob, _oracleAddress, _id));
        proposalSupporters[proposalHash].push(msg.sender);
        if (!proposalExists[proposalHash]) {
            // all this data has to match for each proposal so it's only added once
            proposalExists[proposalHash] = true;
            proposalHashes.push(proposalHash);
            proposalOperations[proposalHash] = ProposalOperation.RemoveJob;
            removeJobProposals[proposalHash] = RemoveJobProposal(_oracleAddress, _id);
        }
    }

    /**
     * Called from whitelisted externals to force stop a round after a given time
     * current Timestamp in milliseconds
     */
    function forceStopRound(uint256 _currentTimestamp) external onlyWhitelisted() roundRunning() {
        // minutes are converted to milliseconds
        require(
            lastRoundStartTimestamp.add((uint256(minPassedMinutesToForceStop).mul(60)).mul(1000)) > _currentTimestamp,
            "Not enough time has passed yet to fource round end"
        );
        triggerEndRound();
    }

    /**
     * current Timestamp in milliseconds
     */
    function proposeStartRound(uint256 _currentTimestamp) external onlyWhitelisted() roundNotRunning() {
        startRoundProposals.push(msg.sender);
        if (startRoundProposals.length > minProposalSupporters) {
            triggerStartRound(_currentTimestamp);
        }
    }

    /**
     * current Timestamp in milliseconds
     */
    function proposeEndRound() external onlyWhitelisted() roundRunning() {
        endRoundProposals.push(msg.sender);
        if (endRoundProposals.length > minProposalSupporters) {
            triggerEndRound();
        }
    }

    function triggerEndRound() private {
        // reset endRoundProposals
        delete endRoundProposals;
        isRoundRunning = false;
        onRoundEnd();
    }

    /**
     * current Timestamp in milliseconds
     */
    function triggerStartRound(uint256 _currentTimestamp) private {
        // reset startRoundProposals
        delete startRoundProposals;
        isRoundRunning = true;
        lastRoundStartTimestamp = _currentTimestamp;
    }

    modifier roundRunning() {
        require(isRoundRunning, "No round is running");
        _;
    }

    modifier roundNotRunning() {
        require(!isRoundRunning, "Round is running");
        _;
    }
}
