// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {Governance} from "../tornado-governance/contracts/Governance.sol";
import {LotteryRandomNumberConsumer} from "./LotteryRandomNumberConsumer.sol";
import {ABDKMath64x64} from "./libraries/ABDKMath64x64.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//import "hardhat/console.sol";

abstract contract TornadoLotteryFunctionality is LotteryRandomNumberConsumer {
    using SafeMath for int128;

    enum LotteryState {
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
        mapping(uint256 => bool) rolledAlready;
    }

    struct UserVotingReturnData {
        uint256 tornSquareRoot;
        uint256 position;
        bool rolledAlready;
    }

    struct ProposalData {
        ProposalStateAndValidity proposalState;
        uint256 sqrtTornSum;
        uint256 totalTornRewards;
        uint256 positionCounter;
        uint256 rewardRoundTimeDifference;
        uint256 startTime;
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
        idToUserVotingData[account][proposalId].position = proposalWhitelist[
            proposalId
        ].positionCounter;
        proposalWhitelist[proposalId].positionCounter++;
        _setTornSquareRootOfAccount(proposalId, account, accountVotes);
    }

    function getUserVotingData(address account, uint256 proposalId)
        external
        view
        returns (UserVotingReturnData memory)
    {
        bool rolledAlready = false;
        if (_checkIfProposalIsReadyForPayouts(proposalId)) {
            uint256 timeIndex = (block.timestamp)
                .sub(proposalWhitelist[proposalId].startTime)
                .div(proposalWhitelist[proposalId].rewardRoundTimeDifference);
            rolledAlready = idToUserVotingData[account][proposalId]
                .rolledAlready[timeIndex];
        }

        UserVotingReturnData memory toReturn = UserVotingReturnData(
            idToUserVotingData[account][proposalId].tornSquareRoot,
            idToUserVotingData[account][proposalId].position,
            rolledAlready
        );

        return toReturn;
    }

    function getProposalData(uint256 proposalId)
        external
        view
        returns (ProposalData memory)
    {
        return proposalWhitelist[proposalId];
    }

    function _prepareProposalForPayouts(uint256 proposalId) internal virtual {
        require(
            _checkIfProposalIsValid(proposalId),
            "can't prepare payout for invalid proposal"
        );
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
        proposalWhitelist[proposalId].startTime = block.timestamp;
        getRandomNumber();
        idForLatestRandomNumber = proposalId;
    }

    function _whitelistProposal(
        uint256 proposalId,
        address torn,
        uint256 proposalRewards,
        uint256 rewardRoundTimeDifference
    ) internal {
        require(!(_checkIfProposalIsValid(proposalId)), "already whitelisted");
        require(
            _checkIfProposalIsPending(proposalId) ||
                _checkIfProposalIsActive(proposalId),
            "not in valid state for whitelisting"
        );
        proposalWhitelist[proposalId].proposalState = ProposalStateAndValidity
            .ValidProposalForLottery;
        proposalWhitelist[proposalId].totalTornRewards = proposalRewards;
        proposalWhitelist[proposalId]
            .rewardRoundTimeDifference = rewardRoundTimeDifference;
        //rest are initialized automatically to 0
        require(
            IERC20(torn).transferFrom(
                TornadoMultisig,
                address(this),
                proposalRewards
            ),
            "TORN transfer failed"
        );
    }

    function _rollAndTransferUserForProposal(
        uint256 proposalId,
        address torn,
        address account
    ) internal {
        uint256 timeIndex = 0;
        if (!(block.timestamp == proposalWhitelist[proposalId].startTime)) {
            timeIndex = (block.timestamp)
                .sub(proposalWhitelist[proposalId].startTime)
                .div(proposalWhitelist[proposalId].rewardRoundTimeDifference);
        }

        require(
            !idToUserVotingData[account][proposalId].rolledAlready[timeIndex],
            "user rolled already"
        );
        require(
            _checkIfProposalIsReadyForPayouts(proposalId),
            "proposal not ready for payouts"
        );
        require(
            _checkIfProposalIsFinished(proposalId),
            "Proposal not executed/defeated"
        );
        require(
            !(proposalWhitelist[proposalId].positionCounter == 0),
            "every reward disributed"
        );

        uint256 roll = expand(
            proposalId,
            uint256(
                keccak256(
                    abi.encode(
                        idToUserVotingData[account][proposalId].position,
                        timeIndex
                    )
                )
            ),
            proposalWhitelist[proposalId].sqrtTornSum
        );
        //	console.log("Whale %s rolled: %s", account, roll);
        //	console.log("Timestamp: %s", block.timestamp);

        idToUserVotingData[account][proposalId].rolledAlready[timeIndex] = true;

        if (roll <= idToUserVotingData[account][proposalId].tornSquareRoot) {
            uint256 toTransfer = (
                proposalWhitelist[proposalId].totalTornRewards
            ).div(proposalWhitelist[proposalId].positionCounter);
            require(
                IERC20(torn).transfer(account, toTransfer),
                "Lottery reward transfer failed"
            );
            proposalWhitelist[proposalId].totalTornRewards = proposalWhitelist[
                proposalId
            ].totalTornRewards.sub(toTransfer);
            proposalWhitelist[proposalId].positionCounter--;
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

    function _setTornSquareRootOfAccount(
        uint256 proposalId,
        address account,
        uint256 accountVotes
    ) private returns (uint256) {
        uint256 newSquareRoot = _calculateSquareRoot(accountVotes);
        uint256 oldSqrtTornSum = proposalWhitelist[proposalId].sqrtTornSum;
        proposalWhitelist[proposalId].sqrtTornSum = oldSqrtTornSum.sub(
            idToUserVotingData[account][proposalId].tornSquareRoot
        );
        idToUserVotingData[account][proposalId].tornSquareRoot = newSquareRoot;
        proposalWhitelist[proposalId].sqrtTornSum += newSquareRoot;
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

    function _checkIfProposalIsValid(uint256 proposalId)
        private
        view
        returns (bool)
    {
        return (proposalWhitelist[proposalId].proposalState ==
            ProposalStateAndValidity.ValidProposalForLottery);
    }

    function _checkIfProposalIsReadyForPayouts(uint256 proposalId)
        private
        view
        returns (bool)
    {
        return (proposalWhitelist[proposalId].proposalState ==
            ProposalStateAndValidity.ProposalReadyForPayouts);
    }
}
