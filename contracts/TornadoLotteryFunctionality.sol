// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import {Governance} from "../tornado-governance/contracts/Governance.sol";
import {LotteryRandomNumberConsumer} from "./LotteryRandomNumberConsumer.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ABDKMath64x64} from "abdk-libraries-solidity/ABDKMath64x64.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

// will be inherited by either a governance upgrade or a seperate contract

contract TornadoLotteryFunctionality is LotteryRandomNumberConsumer, Ownable {
    using SafeMath for uint256;
    using SafeMath for uint128;

    enum LotteryState {
        NotInitialized,
        RegisteringVoters,
        PreparingRewards,
        RewardsDistributed,
        PreparingNewRound
    }

    enum ProposalStateAndValidity {
        InvalidProposalForLottery,
        ValidProposalForLottery,
        ExecutedProposal
    }

    struct UserVotingData {
        uint256 tornSquareRoot;
    }

    Governance public TornadoGovernance;
    mapping(address => mapping(uint256 => UserVotingData))
        public idToUserVotingData;
    address[][] public votersForProposal;
    mapping(uint256 => ProposalStateAndValidity) public proposalWhitelist;

    constructor(address _governance) public LotteryRandomNumberConsumer() {
        TornadoGovernance = Governance(_governance);
    }

    function _calculateSquareRoot(uint256 number) internal returns (uint256) {
        uint128 number64 = uint128((number << 64).div(1e18));
        uint128 squareRoot64 = ABDKMath64x64.sqrt(number64);
        return uint256(((squareRoot64).mul(1e18)) >> 64);
    }

    function _setTornSquareRootOfAccount(address account, uint256 proposalId)
        internal
    {
        idToUserVotingData[account][proposalId]
            .tornSquareRoot = _calculateSquareRoot(
            Governance.proposals[proposalId].receipts[account].votes
        );
    }

    function _registerAccountWithLottery(uint256 proposalId) internal {
        require(
            _checkIfProposalHasEnded(proposalId),
            "Proposal has not finished yet"
        );
        require(
            _checkIfAccountHasVoted(msg.sender, proposalId),
            "Account has not voted on this proposal"
        );
	require(
	    _checkIfProposalIsValid(proposalId),
	    "Proposal not whitelisted"
	);
        votersForProposal[proposalId].push(msg.sender);
        _setTornSquareRootOfAccount(msg.sender, proposalId);
    }

    function _checkIfProposalHasEnded(uint256 proposalId)
        internal
	view
        returns (bool)
    {
        return ((Governance.state(proposalId) ==
            Governance.ProposalState.Executed) ||
            (Governance.state(proposalId) ==
                Governance.ProposalState.Defeated));
    }

    function _checkIfAccountHasVoted(address account, uint256 proposalId)
        internal
        view
        returns (bool)
    {
        return Governance.proposals[proposalId].receipts[account].hasVoted;
    }

    function _checkIfProposalIsValid(uint256 proposalId)
        internal
	view
	returns (bool)
    {
	return (proposalWhitelist[proposalId] == ProposalStateAndValidity.ValidProposalForLottery);
    }
}
