// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {Governance} from "../tornado-governance/contracts/Governance.sol";
import {LotteryRandomNumberConsumer} from "./LotteryRandomNumberConsumer.sol";
import {ABDKMath64x64} from "./libraries/ABDKMath64x64.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract TornadoLotteryFunctionality is LotteryRandomNumberConsumer {
    using SafeMath for int128;

    enum LotteryState {
        Idle,
        PreparingProposalForPayouts
    }

    enum ProposalStateAndValidity {
        PreparingProposalForPayouts,
        ProposalReadyForPayouts
    }

    struct UserVotingData {
        bool rolledAlready;
    }

    struct ProposalData {
        ProposalStateAndValidity proposalState;
        uint256 sqrtTornSum;
        uint256 transferPerWinner;
        uint256[] winningNumbers;
        uint256[] intervals;
        mapping(address => uint256) accountPosition;
    }

    struct ReturnableProposalDataForAccount {
        ProposalStateAndValidity proposalState;
        uint256 sqrtTornSum;
        uint256 transferPerWinner;
        uint256 accountPosition;
        uint256 accountSqrtTorn;
    }

    address public constant TornadoMultisig =
        address(0xb04E030140b30C27bcdfaafFFA98C57d80eDa7B4);

    mapping(address => mapping(uint256 => UserVotingData))
        public idToUserVotingData;
    mapping(uint256 => ProposalData) public proposalWhitelist;

    LotteryState public lotteryState;

    event VoterRegistrationSuccessful(uint256 proposalId, address voter);
    event VoterRegistrationFailed(uint256 proposalId, address voter);

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

    function registerAccountWithLottery(
        uint256 proposalId,
        address account,
        uint256 accountVotes
    ) external {
        require(
            msg.sender == address(this),
            "only governance may call this function"
        );
        require(_checkIfProposalIsActive(proposalId), "Proposal has finished");
        require(
            _checkIfAccountHasVoted(proposalId, account),
            "Account has not voted on this proposal"
        );
        _setTornSquareRootOfAccount(proposalId, account, accountVotes);
    }

    function claimRewards(uint256 proposalId) external virtual;

    function getUserVotingData(address account, uint256 proposalId)
        external
        view
        returns (UserVotingData memory)
    {
        return idToUserVotingData[account][proposalId];
    }

    function getProposalDataForAccount(uint256 proposalId, address account)
        external
        view
        returns (ReturnableProposalDataForAccount memory)
    {
        uint256 accountIndex = proposalWhitelist[proposalId].accountPosition[
            account
        ];
        return
            ReturnableProposalDataForAccount(
                proposalWhitelist[proposalId].proposalState,
                proposalWhitelist[proposalId].sqrtTornSum,
                proposalWhitelist[proposalId].transferPerWinner,
                accountIndex,
                proposalWhitelist[proposalId].intervals[accountIndex]
            );
    }

    function getWinningNumbersForProposal(uint256 proposalId)
        external
        view
        returns (uint256[] memory)
    {
        return proposalWhitelist[proposalId].winningNumbers;
    }

    function getIntervalsForProposal(uint256 proposalId)
        external
        view
        returns (uint256[] memory)
    {
        return proposalWhitelist[proposalId].intervals;
    }

    function _prepareProposalForPayouts(
        uint256 proposalId,
        uint256 proposalRewards,
        uint256 numberOfWinners
    ) internal virtual {
        require(
            _checkIfProposalIsFinished(proposalId),
            "only when proposal is defeated or executed! (randomness)"
        );
        require(
            lotteryState == LotteryState.Idle,
            "already preparing another proposal"
        );

        lotteryState = LotteryState.PreparingProposalForPayouts;
        proposalWhitelist[proposalId].proposalState = ProposalStateAndValidity
            .PreparingProposalForPayouts;
        proposalWhitelist[proposalId].transferPerWinner = proposalRewards.div(
            numberOfWinners
        );

        for (uint256 i = 0; i < numberOfWinners; i++) {
            proposalWhitelist[proposalId].winningNumbers.push(0); // for length
        }

        idForLatestRandomNumber = proposalId;
        getRandomNumber();
    }

    function _rollAndTransferUserForProposal(
        uint256 proposalId,
        address torn,
        address account
    ) internal {
        require(
            !idToUserVotingData[account][proposalId].rolledAlready,
            "user rolled already"
        );
        require(
            _checkIfProposalIsReadyForPayouts(proposalId),
            "proposal not ready for payouts"
        );

        idToUserVotingData[account][proposalId].rolledAlready = true;

        if (_checkIfAccountHasWon(proposalId, account)) {
            require(
                IERC20(torn).transfer(
                    account,
                    proposalWhitelist[proposalId].transferPerWinner
                ),
                "Lottery reward transfer failed"
            );
        }
    }

    function _errorHandledRegisterAccountWithLottery(
        uint256 proposalId,
        address account,
        uint256 accountVotes
    ) internal {
        try this.registerAccountWithLottery(proposalId, account, accountVotes) {
            emit VoterRegistrationSuccessful(proposalId, account);
        } catch {
            emit VoterRegistrationFailed(proposalId, account);
        }
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        randomResults[idForLatestRandomNumber] = randomness;
        proposalWhitelist[idForLatestRandomNumber]
            .proposalState = ProposalStateAndValidity.ProposalReadyForPayouts;
        lotteryState = LotteryState.Idle;
        for (
            uint256 i = 0;
            i <
            proposalWhitelist[idForLatestRandomNumber].winningNumbers.length;
            i++
        ) {
            proposalWhitelist[idForLatestRandomNumber].winningNumbers[
                i
            ] = expand(
                randomness,
                i + 1,
                proposalWhitelist[idForLatestRandomNumber].sqrtTornSum
            );
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

    function _checkIfAccountHasWon(uint256 proposalId, address account)
        public
        view
        returns (bool)
    {
        uint256 cumulativeSum = 0;
        uint256 accountIndex = proposalWhitelist[proposalId].accountPosition[
            account
        ];
        for (uint256 i = 0; i < accountIndex; i++) {
            cumulativeSum += proposalWhitelist[proposalId].intervals[i];
        }

        for (
            uint256 i = 0;
            i < proposalWhitelist[proposalId].winningNumbers.length;
            i++
        ) {
            if (
                _checkRoll(
                    cumulativeSum,
                    cumulativeSum.add(
                        proposalWhitelist[proposalId].intervals[accountIndex]
                    ),
                    proposalWhitelist[proposalId].winningNumbers[i]
                )
            ) {
                return true;
            }
        }
        return false;
    }

    function _checkRoll(
        uint256 cumulativeSum,
        uint256 intervalEnd,
        uint256 roll
    ) private pure returns (bool) {
        if (cumulativeSum <= roll) {
            if (roll < intervalEnd) {
                return true;
            }
        }
        return false;
    }

    function _setTornSquareRootOfAccount(
        uint256 proposalId,
        address account,
        uint256 accountVotes
    ) private returns (uint256) {
        uint256 newSquareRoot = _calculateSquareRoot(accountVotes);
        uint256 oldSum = proposalWhitelist[proposalId].sqrtTornSum;
        uint256 accountIndex = proposalWhitelist[proposalId].accountPosition[
            account
        ];

        proposalWhitelist[proposalId].sqrtTornSum = oldSum
            .sub(proposalWhitelist[proposalId].intervals[accountIndex])
            .add(newSquareRoot);

        if (proposalWhitelist[proposalId].accountPosition[account] > 0) {
            proposalWhitelist[proposalId].intervals.push(newSquareRoot);
            proposalWhitelist[proposalId].accountPosition[
                account
            ] = proposalWhitelist[proposalId].intervals.length;
        } else {
            proposalWhitelist[proposalId].intervals[
                accountIndex
            ] = newSquareRoot;
        }

        return newSquareRoot;
    }

    function _checkIfProposalIsActive(uint256 proposalId)
        internal
        view
        virtual
        returns (bool);

    function _checkIfProposalIsPending(uint256 proposalId)
        internal
        view
        virtual
        returns (bool);

    function _checkIfProposalIsFinished(uint256 proposalId)
        internal
        view
        virtual
        returns (bool);

    function _checkIfAccountHasVoted(uint256 proposalId, address account)
        internal
        view
        virtual
        returns (bool);

    function _checkIfProposalIsReadyForPayouts(uint256 proposalId)
        private
        view
        returns (bool)
    {
        return (proposalWhitelist[proposalId].proposalState ==
            ProposalStateAndValidity.ProposalReadyForPayouts);
    }
}
