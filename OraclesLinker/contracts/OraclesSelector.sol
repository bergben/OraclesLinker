pragma solidity >=0.5.17;

import "./OraclesStore.sol";
import "./OraclesLink.sol";


/**
 * @title OracleSelector is a contract which randomly picks Chainlink Oracle Nodes to fulfill a given requests
 */
contract OraclesSelector is OraclesStore {
    function select(
        OraclesLink.JobType jobType,
        OraclesLink.OracleLevel,
        uint256 nonce,
        uint256[] memory alreadySelected
    )
        internal
        returns (
            address oracleAddress,
            bytes32 jobId,
            uint256 payment
        )
    {
        // get the current random value from the OraclesStore
        // get the count of oracles available for jobType and level
        // find some random number between 1 and count of oracles
        // must everytime be different through random value, nonce etc.
        // make sure the random number is not in the array of already selected oracles
        // fetch the oracle for the random number (mapping in OraclesStore?)
        // return it
        // return (0x0000000000000000, "ss", 3);
    }
}
