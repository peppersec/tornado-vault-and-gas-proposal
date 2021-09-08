// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ABDKMath64x64 } from "../libraries/ABDKMath64x64.sol";
import { LotteryRandomNumberConsumer } from "./LotteryRandomNumberConsumer.sol";
import { GovernanceLotteryUpgrade } from "./GovernanceLotteryUpgrade.sol";
import { Governance } from "../Governance.sol";
import { ImmutableGovernanceInformation } from "../ImmutableGovernanceInformation.sol";

contract TornadoLottery is LotteryRandomNumberConsumer, ImmutableGovernanceInformation {
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

  uint256 public constant LOTTERY_WINNERS = 10;

  mapping(uint256 => SingleUserVoteData[]) public lotteryUserData;
  mapping(uint256 => ProposalData) public proposalsData;

  LotteryState public lotteryState;
  
  /**
  @dev Order of arguments in constructor for LotteryConsumerBase which takes data for Chainlink VRFConsumerBase:
    LotteryRandomNumberConsumer(
      VRF_COORDINATOR_ADDRESS,
      CHAINLINK_TOKEN_ADDRESS,
      KEY_HASH
    )
  All data is valid ONLY for Ethereum Mainnet.
  */
  constructor()
    public
    LotteryRandomNumberConsumer(
      0xf0d54349aDdcf704F77AE15b96510dEA15cb7952,
      0x514910771AF9Ca656af840dff83E8264EcF986CA,
      bytes32(0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445)
    )
    ImmutableGovernanceInformation()
  {
    lotteryState = LotteryState.Idle;
  }

  function registerLotteryAccount(
    uint256 proposalId,
    address account,
    uint96 accountVotes
  ) external onlyGovernance {
    _registerUserData(proposalId, account, accountVotes);
  }

  function prepareProposalForPayouts(uint256 proposalId, uint256 proposalRewards, uint256 _fee) external onlyMultisig {
    require(_checkIfProposalIsFinished(proposalId), "proposal not finished");
    require(lotteryState == LotteryState.Idle, "preparing another proposal");
    require(proposalRewards <= 1e21, "reward limit");

    lotteryState = LotteryState.PreparingProposalForPayouts;
    proposalsData[proposalId] = ProposalData(
      ProposalState.PreparingProposalForPayouts,
      uint248(proposalRewards.div(LOTTERY_WINNERS))
    );

    idForLatestRandomNumber = proposalId;
    getRandomNumber(_fee);
  }

  function claimRewards(
    uint256 proposalId,
    uint256 voteIndex,
    uint256 numberIndex
  ) external {
    require(msg.sender == lotteryUserData[proposalId][voteIndex].voter, "invalid claimer/claimed once");
    require(_checkIfProposalIsReadyForPayouts(proposalId), "not ready for payouts");
    require(numberIndex < LOTTERY_WINNERS, "cant roll higher");

    lotteryUserData[proposalId][voteIndex].voter = address(0);

    if (
      checkIfAccountHasWon(
        proposalId,
        voteIndex,
        expand(
          randomNumbers[proposalId],
          numberIndex,
          getSqrtTornSumForProposal(proposalId).add(1)
        )
      )
    ) {
      require(
        IERC20(TornTokenAddress).transferFrom(
          GovernanceAddress,
          msg.sender,
          uint256(proposalsData[proposalId].proposalRewardPerWinner)
        ),
        "Lottery reward transfer failed"
      );
    }
  }

  function findUserIndex(uint256 proposalId, address account) external view returns (uint256) {
    for (uint256 i = 0; i < lotteryUserData[proposalId].length; i++) {
      if (lotteryUserData[proposalId][i].voter == account) {
        return i;
      }
    }
    return 0;
  }

  function getSqrtTornSumForProposal(uint256 proposalId) public view returns (uint256) {
    return uint256(lotteryUserData[proposalId][lotteryUserData[proposalId].length - 1].tornSqrt);
  }

  function checkIfAccountHasWon(
    uint256 proposalId,
    uint256 voteIndex,
    uint256 lotteryNumber
  ) public view returns (bool) {
    return (_getSqrtTornForVoter(proposalId, int256(voteIndex) - 1) <= lotteryNumber &&
      lotteryNumber < lotteryUserData[proposalId][voteIndex].tornSqrt);
  }

  function fulfillRandomness(bytes32, uint256 randomness) internal override {
    require(proposalsData[idForLatestRandomNumber].proposalState == ProposalState.PreparingProposalForPayouts, "invalid state");
    lotteryState = LotteryState.Idle;
    proposalsData[idForLatestRandomNumber].proposalState = ProposalState.ProposalReadyForPayouts;
    randomNumbers[idForLatestRandomNumber] = randomness;
  }

  function _registerUserData(
    uint256 proposalId,
    address account,
    uint96 accountVotes
  ) private {
    lotteryUserData[proposalId].push(
      SingleUserVoteData(
        uint96(
          _calculateSquareRoot(accountVotes).add(_getSqrtTornForVoter(proposalId, int256(lotteryUserData[proposalId].length) - 1))
        ),
        account
      )
    );
  }

  function _getSqrtTornForVoter(uint256 proposalId, int256 voteIndex) private view returns (uint256) {
    return (voteIndex >= 0) ? lotteryUserData[proposalId][uint256(voteIndex)].tornSqrt : 0;
  }

  function _checkIfProposalIsActive(uint256 proposalId) private view returns (bool) {
    return (GovernanceLotteryUpgrade(GovernanceAddress).state(proposalId) == Governance.ProposalState.Active);
  }

  function _checkIfProposalIsPending(uint256 proposalId) private view returns (bool) {
    return (GovernanceLotteryUpgrade(GovernanceAddress).state(proposalId) == Governance.ProposalState.Pending);
  }

  function _checkIfProposalIsFinished(uint256 proposalId) private view returns (bool) {
    return (GovernanceLotteryUpgrade(GovernanceAddress).state(proposalId) == Governance.ProposalState.Defeated ||
      GovernanceLotteryUpgrade(GovernanceAddress).state(proposalId) == Governance.ProposalState.Executed);
  }

  function _checkIfProposalIsReadyForPayouts(uint256 proposalId) private view returns (bool) {
    return (proposalsData[proposalId].proposalState == ProposalState.ProposalReadyForPayouts);
  }

  function _calculateSquareRoot(uint256 number) private pure returns (uint256) {
    int128 number64 = int128((number << 64).div(1e18));
    int128 squareRoot64 = ABDKMath64x64.sqrt(number64);
    return (uint256(squareRoot64).mul(1e9) >> 64);
  }
}
