// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ABDKMath64x64} from "./libraries/ABDKMath64x64.sol";
import {LotteryRandomNumberConsumer} from "./LotteryRandomNumberConsumer.sol";
import {GovernanceLotteryUpgrade} from "./GovernanceLotteryUpgrade.sol";
import {Governance} from "./virtualGovernance/Governance.sol";

contract TornadoLottery is LotteryRandomNumberConsumer {
    using SafeMath for uint96;

    enum LotteryState {
        Idle,
        PreparingProposalForPayouts
    }

    enum ProposalState {
        ProposalNotPreparedForPayouts,
        PreparingProposalForPayouts,
        ProposalReadyForPayouts
    }

    struct SingleUserVoteData {
        uint96 tornSqrt;
        address voter;
    }

    struct ProposalData {
        ProposalState proposalState;
        uint248 proposalRewardPerWinner;
    }

    address public constant TornadoGovernance =
        address(0x5efda50f22d34F262c29268506C5Fa42cB56A1Ce);

    uint256 public LOTTERY_WINNERS = 10;

    mapping(uint256 => SingleUserVoteData[]) public lotteryUserData;
    mapping(uint256 => ProposalData) public proposalsData;
    mapping(uint256 => uint256[]) public lotteryNumbers;

    LotteryState public lotteryState;

    constructor()
        public
        LotteryRandomNumberConsumer(
            address(0xf0d54349aDdcf704F77AE15b96510dEA15cb7952),
            address(0x514910771AF9Ca656af840dff83E8264EcF986CA),
            bytes32(
                0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445
            ),
            (2 * (10**18))
        )
    {
        lotteryState = LotteryState.Idle;
    }

    modifier onlyGovernance() {
        require(msg.sender == TornadoGovernance, "only governance");
        _;
    }

    function registerAccountWithLottery(
        uint256 proposalId,
        address account,
        uint96 accountVotes
    ) external onlyGovernance {
        require(
            _checkIfAccountHasVoted(proposalId, account),
            "Account has not voted on this proposal"
        );
        _registerUserData(proposalId, account, accountVotes);
    }

    function findUserIndex(uint256 proposalId, address account)
        external
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < lotteryUserData[proposalId].length; i++) {
            if (lotteryUserData[proposalId][i].voter == account) {
                return i;
            }
        }
        return 0;
    }

    function checkIfAccountHasWon(
        uint256 proposalId,
        uint256 voteIndex,
        uint256 numberIndex
    ) public view returns (bool) {
        if (voteIndex > 0) {
            return (lotteryUserData[proposalId][voteIndex - 1].tornSqrt <=
                lotteryNumbers[proposalId][numberIndex] &&
                lotteryNumbers[proposalId][numberIndex] <
                lotteryUserData[proposalId][voteIndex].tornSqrt);
        } else {
            return (lotteryUserData[proposalId][0].tornSqrt <=
                lotteryNumbers[proposalId][numberIndex] &&
                lotteryNumbers[proposalId][numberIndex] <
                lotteryUserData[proposalId][1].tornSqrt);
        }
    }

    function prepareProposalForPayouts(
        uint256 proposalId,
        uint256 proposalRewards
    ) external onlyGovernance {
        require(
            _checkIfProposalIsFinished(proposalId),
            "only when proposal is defeated or executed! (randomness)"
        );
        require(
            lotteryState == LotteryState.Idle,
            "already preparing another proposal"
        );

        lotteryState = LotteryState.PreparingProposalForPayouts;
        proposalsData[proposalId] = ProposalData(
            ProposalState.PreparingProposalForPayouts,
            uint248(proposalRewards.div(LOTTERY_WINNERS))
        );
        lotteryNumbers[proposalId] = new uint256[](LOTTERY_WINNERS);
        idForLatestRandomNumber = proposalId;

        getRandomNumber();
    }

    function claimRewards(
        uint256 proposalId,
        uint256 voteIndex,
        uint256 numberIndex,
        address account,
        address torn
    ) external onlyGovernance {
        require(
            account == lotteryUserData[proposalId][voteIndex].voter,
            "invalid claimer/claimed once"
        );
        require(
            _checkIfProposalIsReadyForPayouts(proposalId),
            "proposal not ready for payouts"
        );

        lotteryUserData[proposalId][voteIndex].voter = address(0);

        if (checkIfAccountHasWon(proposalId, voteIndex, numberIndex)) {
            require(
                IERC20(torn).transferFrom(
                    TornadoGovernance,
                    account,
                    uint256(proposalsData[proposalId].proposalRewardPerWinner)
                ),
                "Lottery reward transfer failed"
            );
        }
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        lotteryState = LotteryState.Idle;
        proposalsData[idForLatestRandomNumber].proposalState = ProposalState
            .ProposalReadyForPayouts;
        lotteryNumbers[idForLatestRandomNumber] = _calculateRandomNumberArray(
            randomness,
            uint256(
                lotteryUserData[idForLatestRandomNumber][
                    lotteryUserData[idForLatestRandomNumber].length - 1
                ].tornSqrt
            ),
            LOTTERY_WINNERS
        );
    }

    function _registerUserData(
        uint256 proposalId,
        address account,
        uint96 accountVotes
    ) private {
        if (lotteryUserData[proposalId].length == 0) {
            lotteryUserData[proposalId].push(
                SingleUserVoteData(
                    uint96(_calculateSquareRoot(accountVotes)),
                    account
                )
            );
        } else {
            lotteryUserData[proposalId].push(
                SingleUserVoteData(
                    uint96(
                        _calculateSquareRoot(accountVotes).add(
                            lotteryUserData[proposalId][
                                lotteryUserData[proposalId].length - 1
                            ].tornSqrt
                        )
                    ),
                    account
                )
            );
        }
    }

    function _checkIfProposalIsActive(uint256 proposalId)
        private
        view
        returns (bool)
    {
        return (GovernanceLotteryUpgrade(TornadoGovernance).state(proposalId) ==
            Governance.ProposalState.Active);
    }

    function _checkIfProposalIsPending(uint256 proposalId)
        private
        view
        returns (bool)
    {
        return (GovernanceLotteryUpgrade(TornadoGovernance).state(proposalId) ==
            Governance.ProposalState.Pending);
    }

    function _checkIfProposalIsFinished(uint256 proposalId)
        private
        view
        returns (bool)
    {
        return (GovernanceLotteryUpgrade(TornadoGovernance).state(proposalId) ==
            Governance.ProposalState.Defeated ||
            GovernanceLotteryUpgrade(TornadoGovernance).state(proposalId) ==
            Governance.ProposalState.Executed);
    }

    function _checkIfAccountHasVoted(uint256 proposalId, address account)
        private
        view
        returns (bool)
    {
        return
            GovernanceLotteryUpgrade(TornadoGovernance).hasAccountVoted(
                proposalId,
                account
            );
    }

    function _checkIfProposalIsReadyForPayouts(uint256 proposalId)
        private
        view
        returns (bool)
    {
        return (proposalsData[proposalId].proposalState ==
            ProposalState.ProposalReadyForPayouts);
    }

    function _calculateRandomNumberArray(
        uint256 randomSeed,
        uint256 upperBound,
        uint256 arraySize
    ) private pure returns (uint256[] memory toReturn) {
        toReturn = new uint256[](arraySize);
        for (uint256 i = 0; i < arraySize; i++) {
            toReturn[i] = expand(randomSeed, i, upperBound.add(1));
        }
    }

    function _calculateSquareRoot(uint256 number)
        private
        pure
        returns (uint256)
    {
        int128 number64 = int128((number << 64).div(1e18));
        int128 squareRoot64 = ABDKMath64x64.sqrt(number64);
        return (uint256(squareRoot64).mul(1e9) >> 64);
    }
}
