// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import {Governance} from "../tornado-governance/contracts/Governance.sol";
import {LotteryRandomNumberConsumer} from "./LotteryRandomNumberConsumer.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ABDKMath64x64} from "abdk-libraries-solidity/ABDKMath64x64.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// will be inherited by either a governance upgrade or a seperate contract

abstract contract TornadoLotteryFunctionality is LotteryRandomNumberConsumer, Ownable {
    using SafeMath for uint256;
    using SafeMath for uint128;

    enum LotteryState {
	Paused,
	Idle,
	PreparingProposalForPayouts
    }

    enum ProposalStateAndValidity {
        InvalidProposalForLottery,
        ValidProposalForLottery,
	PreparingProposalForPayouts,
        ProposalReadyForPayouts
    }

    struct UserVotingData {
        uint256 tornSquareRoot;
	uint256 position;
	bool rolledAlready;
    }

    struct ProposalData {
        ProposalStateAndValidity proposalState;
        uint256 sqrtTornSum;
	uint256 totalTornRewards;
	uint256 positionCounter;
    }

    mapping(address => mapping(uint256 => UserVotingData))
        public idToUserVotingData;
    mapping(uint256 => ProposalData) public proposalWhitelist;

    LotteryState public lotteryState;

    constructor() public LotteryRandomNumberConsumer() {
	    lotteryState = LotteryState.Idle;
    }

    function whitelistProposal(uint256 proposalId, address torn, uint256 proposalRewards) external onlyOwner {
	    require(proposalWhitelist[proposalId].proposalState == ProposalStateAndValidity.InvalidProposalForLottery, "already whitelisted");
	    require(_checkIfProposalisPending(proposalId) || _checkIfProposalIsActive(proposalId), "not in valid state for whitelisting");
	    proposalWhitelist[proposalId].proposalState = ProposalStateAndValidity.ValidProposalForLottery;
	    proposalWhitelist[proposalId].totalTornRewards = proposalRewards;
	    //rest are initialized automatically to 0
	    require(IERC20(torn).transferFrom(owner(), address(this), proposalRewards), "TORN transfer failed");
    }

    function prepareProposalForPayouts(uint256 proposalId) external onlyOwner {
	    require(proposalWhitelist[proposalId].proposalState == ProposalStateAndValidity.ValidProposalForLottery, "can't prepare payout yet");
	    require(_checkIfProposalIsFinished(proposalId), "only when proposal is defeated or executed! (randomness)");
	    lotteryState = LotteryState.PreparingProposalForPayouts;
	    proposalWhitelist[proposalId].proposalState = ProposalStateAndValidity.PreparingProposalForPayouts;
	    getRandomNumber();
	    idForLatestRandomNumber = proposalId;
    }

    function _rollAndTransferUserForProposal(uint256 proposalId, address torn, address account) internal {
	require(!idToUserVotingData[account][proposalId].rolledAlready, "user rolled already");
	require(proposalWhitelist[proposalId].proposalState == ProposalStateAndValidity.ProposalReadyForPayouts, "proposal not ready for payouts");
	require(_checkIfProposalIsFinished(proposalId), "Proposal not executed/defeated");

	uint256 roll = expand(idToUserVotingData[account][proposalId].position, proposalWhitelist[proposalId].totalTornRewards);
	idToUserVotingData[account][proposalId].rolledAlready = true;
	if(roll >= idToUserVotingData[account][proposalId].tornSquareRoot) {
		require(IERC20(torn).transfer(account, 
			(proposalWhitelist[proposalId].totalTornRewards).div(
				proposalWhitelist[proposalId].positionCounter
			)
		), "Lottery reward transfer failed");
	}
    }

    function _registerAccountWithLottery(uint256 proposalId, address account)
        internal
    {
        require(
            _checkIfProposalIsActive(proposalId),
            "Proposal has not finished yet"
        );
        require(
            _checkIfAccountHasVoted(proposalId, account),
            "Account has not voted on this proposal"
        );
        require(
            _checkIfProposalIsValid(proposalId),
            "Proposal not whitelisted"
        );
	idToUserVotingData[account][proposalId].position = proposalWhitelist[proposalId].positionCounter;
	proposalWhitelist[proposalId].positionCounter++;
        _setTornSquareRootOfAccount(proposalId, account);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        private
        override
    {
	randomResults[idForLatestRandomNumber] = randomness;
	proposalWhitelist[idForLatestRandomNumber].proposalState = ProposalStateAndValidity.ProposalReadyForPayouts;
	lotteryState = LotteryState.Idle;
    }

    function _calculateSquareRoot(uint256 number) private returns (uint256) {
        uint128 number64 = uint128((number << 64).div(1e18));
        uint128 squareRoot64 = ABDKMath64x64.sqrt(number64);
        return uint256(((squareRoot64).mul(1e18)) >> 64);
    }

    function _setTornSquareRootOfAccount(uint256 proposalId, address account)
        private
        returns (uint256)
    {
        uint256 newSquareRoot = _calculateSquareRoot(
            Governance.proposals[proposalId].receipts[account].votes
        );
	uint256 oldSqrtTornSum = proposalWhitelist[proposalId].sqrtTornSum;
	proposalWhitelist[proposalId].sqrtTornSum = oldSqrtTornSum.sub(idToUserVotingData[account][proposalId].tornSquareRoot);
        idToUserVotingData[account][proposalId].tornSquareRoot = newSquareRoot;
	proposalWhitelist[proposalId].sqrtTornSum += newSquareRoot;
        return newSquareRoot;
    }

    function _checkIfProposalIsActive(uint256 proposalId)
        private
        view
        returns (bool);

    function _checkIfProposalIsPending(uint256 proposalId)
        private
        view
        returns (bool);

    function _checkIfProposalIsFinished(uint256 proposalId)
        private
        view
        returns (bool);

    function _checkIfAccountHasVoted(uint256 proposalId, address account)
        private
        view
        returns (bool);

    function _checkIfProposalIsValid(uint256 proposalId)
        private
        view
        returns (bool);
   {
       return (proposalWhitelist[proposalId].proposalState ==
           ProposalStateAndValidity.ValidProposalForLottery);
   }
}
