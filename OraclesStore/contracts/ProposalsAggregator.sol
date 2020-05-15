pragma solidity >=0.5.17;

import "./Whitelisted.sol";

/**
 * @title ProposalsAggregator is a contract which allows white listed addresses to propose changes to stored oracles
 */
contract ProposalsAggregator is WhiteListed {
    struct AddJobProposal {
        bytes32 id;
        bytes32 jobType;
        uint256 cost;
    }
    uint8 private minMatchingProposals;

    // sender => level => Proposed oracle address to add / remove
    mapping(address => mapping(uint8 => address)) private addOracleProposals;
    mapping(address => mapping(uint8 => address)) private removeOracleProposals;

    // sender => oracleAddress => Proposed job to add
    mapping(address => mapping(address => AddJobProposal)) private addJobProposals;
    // sender => oracleAddress => job id of job proposed to remove
    mapping(address => mapping(address => bytes32)) private removeJobProposals;

    function setMinMatchingProposals(uint8 _min) external onlyOwner{
        minMatchingProposals = _min;
    }

    function proposeAddOracle(address _oracleAddress, uint8 _level) external onlyWhitelisted {
        addOracleProposals[msg.sender][_level] = _oracleAddress;
    }

    function proposeRemoveOracle(address _oracleAddress, uint8 _level) external onlyWhitelisted {
        removeOracleProposals[msg.sender][_level] = _oracleAddress;
    }

    function proposeAddJob(
        address _oracleAddress,
        bytes32 _id,
        bytes32 _jobType,
        uint256 _cost
    ) external onlyWhitelisted {
    }

    function proposeRemoveJob(address _oracleAddress, bytes32 _id) external onlyWhitelisted {}
}