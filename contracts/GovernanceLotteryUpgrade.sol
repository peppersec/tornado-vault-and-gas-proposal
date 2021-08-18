// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {Governance} from "./virtualGovernance/Governance.sol";
import {TornadoLotteryFunctionality} from "./TornadoLotteryFunctionality.sol";
import {GasCalculator} from "./basefee/GasCalculator.sol";

contract GovernanceLotteryUpgrade is
    Governance,
    TornadoLotteryFunctionality,
    GasCalculator
{
    mapping(address => mapping(uint256 => uint256))
        public gasCompensationsForProposal;

    constructor(address _logic)
        public
        Governance()
        TornadoLotteryFunctionality()
        GasCalculator(_logic)
    {}

    /// @notice checker for success on deployment
    /// @return returns precise version of governance
    function version() external pure virtual returns (string memory) {
        return "2.lottery-upgrade";
    }

    function _castVote(
        address voter,
        uint256 proposalId,
        bool support
    ) internal virtual override(Governance) {
        uint256 toBeCompensated = _calcApproxEthUsedForTxNoPriorityFee(
            address(this),
            abi.encodeWithSignature(
                "_castVoteLogic(address,uint256,bool)",
                voter,
                proposalId,
                support
            )
        );
        gasCompensationsForProposal[voter][proposalId] = toBeCompensated;
    }

    function _checkIfProposalIsActive(uint256 proposalId)
        internal
        view
        override
        returns (bool)
    {
        return (state(proposalId) == ProposalState.Active);
    }

    function _checkIfProposalIsPending(uint256 proposalId)
        internal
        view
        override
        returns (bool)
    {
        return (state(proposalId) == ProposalState.Pending);
    }

    function _checkIfProposalIsFinished(uint256 proposalId)
        internal
        view
        override
        returns (bool)
    {
        return ((state(proposalId) == ProposalState.Executed) ||
            (state(proposalId) == ProposalState.Defeated));
    }

    function _checkIfAccountHasVoted(uint256 proposalId, address account)
        internal
        view
        override
        returns (bool)
    {
        return (proposals[proposalId].receipts[account]).hasVoted;
    }

    function _castVoteLogic(
        address voter,
        uint256 proposalId,
        bool support
    ) private {
        super._castVote(voter, proposalId, support);
        _errorHandledRegisterAccountWithLottery(
            proposalId,
            voter,
            proposals[proposalId].receipts[voter].votes
        );
    }
}
