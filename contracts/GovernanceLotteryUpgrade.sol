// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import {Governance} from "../tornado-governance/contracts/Governance.sol";

contract GovernanceLotteryUpgrade is Governance, TornadoLotteryFunctionality {

    /// @notice checker for success on deployment
    /// @return returns precise version of governance
    function version() external pure virtual returns (string memory) {
        return "2.lottery-upgrade";
    }

    function _checkIfProposalIsActive(uint256 proposalId)
        private
        view
        returns (bool)
    {
	return (state(proposalId) == ProposalState.Active);
    }

    function _checkIfProposalIsPending(uint256 proposalId)
        private
        view
        returns (bool)
    {
	return (state(proposalId) == ProposalState.Pending);
    }

    function _checkIfProposalIsFinished(uint256 proposalId)
        private
        view
        returns (bool)
    {
	return ((state(proposalId) == ProposalState.Executed) || (state(proposalId) == ProposalState.Defeated));
    }

    function _checkIfAccountHasVoted(uint256 proposalId, address account)
        private
        view
        returns (bool);
    {
	return proposals[proposalId].receipts[account].hasVoted;
    }
}

