pragma solidity >=0.5.17;

import "./Whitelisted.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";


/**
 * @title ProposalsHandler is a contract which handles rounds for proposals from whitelisted externals
 */
contract ProposalsHandler is WhiteListed {
    using SafeMath for uint256;

    uint8 private minMatchingProposals;
    address[] private startRoundProposals;
    address[] private endRoundProposals;
    bool private isRoundRunning;
    uint256 private lastRoundStartTimestamp;
    uint8 private minPassedMinutesToForceStop;

    function setMinMatchingProposals(uint8 _min) external onlyOwner {
        minMatchingProposals = _min;
    }

    function setMinPassedMinutesToForceStop(uint8 _min) external onlyOwner {
        minPassedMinutesToForceStop = _min;
    }

    /**
     * Called from whitelisted externals to force stop a round after a given time
     * current Timestamp in milliseconds
     */
    function forceStopRound(uint256 _currentTimestamp)
        external
        onlyWhitelisted()
        roundRunning()
        minutesPassedSinceRoundStart(_currentTimestamp, minPassedMinutesToForceStop)
    {
        isRoundRunning = false;
    }

    /**
     * current Timestamp in milliseconds
     */
    function proposeStartRound(uint256 _currentTimestamp) external onlyWhitelisted() roundNotRunning() {
        startRoundProposals.push(msg.sender);
        if (startRoundProposals.length > minMatchingProposals) {
            triggerStartRound(_currentTimestamp);
        }
    }

    /**
     * current Timestamp in milliseconds
     */
    function proposeEndRound() external onlyWhitelisted() roundRunning() {
        endRoundProposals.push(msg.sender);
        if (endRoundProposals.length > minMatchingProposals) {
            isRoundRunning = false;
            delete endRoundProposals;
        }
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

    modifier minutesPassedSinceRoundStart(uint256 _currentTimestamp, uint8 _minutes) {
        // minutes are converted to milliseconds
        require(
            lastRoundStartTimestamp.add((_minutes.mul(60)).mul(1000)) > _currentTimestamp,
            "Not enough time has passed yet to fource round end"
        );
        _;
    }
}
