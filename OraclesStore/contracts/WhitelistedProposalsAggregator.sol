pragma solidity >=0.5.17;

import "./WhitelistedProposalsCoordinator.sol";


/**
 * @title WhitelistedProposalsAggregator is a contract which allows white listed addresses to propose changes to stored oracles
 */
contract WhitelistedProposalsAggregator is WhitelistedProposalsCoordinator {
    bytes32[] internal approvedAddOracleKeys;
    bytes32[] internal approvedRemoveOracleKeys;
    bytes32[] internal approvedAddJobKeys;
    bytes32[] internal approvedRemoveJobKeys;

    /**
     * overriden from parent contract
     */
    function onProposalsAggregated() internal;

    /**
     * overrides method triggered from child contract on round end
     */
    function onRoundEnd() internal {
        // filter out the proposals that do not have enough supporters
        for (uint256 i = 0; i < proposalHashes.length; i++) {
            bytes32 key = proposalHashes[i];
            if (proposalSupporters[key].length < minProposalSupporters) {
                removeProposalMappings(key);
            } else {
                if (proposalOperations[key] == ProposalOperation.AddOracle) {
                    approvedAddOracleKeys.push(key);
                }
                if (proposalOperations[key] == ProposalOperation.RemoveOracle) {
                    approvedRemoveOracleKeys.push(key);
                }
                if (proposalOperations[key] == ProposalOperation.AddJob) {
                    approvedAddJobKeys.push(key);
                }
                if (proposalOperations[key] == ProposalOperation.RemoveJob) {
                    approvedRemoveJobKeys.push(key);
                }
            }
        }
        delete proposalHashes;
        onProposalsAggregated();
    }

    function removeProposalMappings(bytes32 key) internal {
        delete proposalSupporters[key];
        delete proposalExists[key];
        if (proposalOperations[key] == ProposalOperation.AddOracle) {
            delete addOracleProposals[key];
        }
        if (proposalOperations[key] == ProposalOperation.RemoveOracle) {
            delete removeOracleProposals[key];
        }
        if (proposalOperations[key] == ProposalOperation.AddJob) {
            delete addJobProposals[key];
        }
        if (proposalOperations[key] == ProposalOperation.RemoveJob) {
            delete removeJobProposals[key];
        }

        delete proposalOperations[key];
    }
}
