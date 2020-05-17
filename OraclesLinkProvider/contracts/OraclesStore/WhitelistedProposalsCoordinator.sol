pragma solidity 0.6.8;
/** SPDX-License-Identifier: MIT*/

import "./Whitelisted.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";


/**
 * @title WhitelistedProposalsCoordinator is a contract which handles proposals for oracle changes in rounds from whitelisted externals
 */
abstract contract WhitelistedProposalsCoordinator is Whitelisted {
    using SafeMath for uint256;
    enum ProposalOperation {AddOracle, RemoveOracle, AddJob, RemoveJob}

    event ProposalReceived(address sender, bytes32 proposalHash);
    event MinProposalSupportersChanged(uint8 minSupporters);
    event MinPassedMinutesToForceStopChanged(uint8 minMinutes);
    event RoundStarted(address sender, uint256 currentTimestamp);
    event RoundEnded(address sender, uint256 currentTimestamp);
    event RoundForceStopped(address sender, uint256 currentTimestamp, uint256 roundStartTimestamp);
    event StartRoundProposed(address sender, uint256 currentTimestamp);
    event EndRoundProposed(address sender, uint256 currentTimestamp);

    uint8 internal minProposalSupporters = 1;
    bool private isRoundRunning = false;
    uint8 private minPassedMinutesToForceStop = 20;
    address[] private startRoundProposals;
    address[] private endRoundProposals;
    uint256 internal lastRoundStartTimestamp;

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

    function onRoundEnd() internal virtual;

    function setMinProposalSupporters(uint8 _min) external onlyOwner() {
        minProposalSupporters = _min;
        emit MinProposalSupportersChanged(_min);
    }

    function setMinPassedMinutesToForceStop(uint8 _min) external onlyOwner() {
        minPassedMinutesToForceStop = _min;
        emit MinPassedMinutesToForceStopChanged(_min);
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
        emit ProposalReceived(msg.sender, proposalHash);
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
        emit ProposalReceived(msg.sender, proposalHash);
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
        emit ProposalReceived(msg.sender, proposalHash);
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
        emit ProposalReceived(msg.sender, proposalHash);
    }

    /**
     * Called from whitelisted externals to force stop a round after a given time
     * current Timestamp in milliseconds
     */
    function forceStopRound() external onlyWhitelisted() roundRunning() {
        // safe to use here because tolerance by miner interference is +-30sec.
        uint256 currentTimestamp = block.timestamp;
        // minutes are converted to milliseconds
        require(
            lastRoundStartTimestamp.add(lastRoundStartTimestamp.add((uint256(minPassedMinutesToForceStop).mul(60)).mul(1000))) >
                currentTimestamp,
            "Not enough time has passed yet to fource round end"
        );
        triggerEndRound(currentTimestamp);
        emit RoundForceStopped(msg.sender, currentTimestamp, lastRoundStartTimestamp);
    }

    /**
     * current Timestamp in milliseconds
     */
    function proposeStartRound(uint256 _currentTimestamp) external onlyWhitelisted() roundNotRunning() {
        emit StartRoundProposed(msg.sender, _currentTimestamp);
        startRoundProposals.push(msg.sender);
        if (startRoundProposals.length >= minProposalSupporters) {
            triggerStartRound(_currentTimestamp);
        }
    }

    /**
     * current Timestamp in milliseconds
     */
    function proposeEndRound(uint256 _currentTimestamp) external onlyWhitelisted() roundRunning() {
        emit EndRoundProposed(msg.sender, _currentTimestamp);
        endRoundProposals.push(msg.sender);
        if (endRoundProposals.length >= minProposalSupporters) {
            triggerEndRound(_currentTimestamp);
        }
    }

    /**
     * current Timestamp in milliseconds
     */
    function triggerEndRound(uint256 _currentTimestamp) private {
        // reset endRoundProposals
        delete endRoundProposals;
        isRoundRunning = false;
        emit RoundEnded(msg.sender, _currentTimestamp);
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
        emit RoundStarted(msg.sender, _currentTimestamp);
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
