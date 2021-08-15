// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import {Governance} from "../tornado-governance/contracts/Governance.sol";
import {LotteryRandomNumberConsumer} from "./LotteryRandomNumberConsumer.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ABDKMath64x64} from "abdk-libraries-solidity/ABDKMath64x64.sol";

// will be inherited by either a governance upgrade or a seperate contract 

contract TornadoLotteryFunctionality is LotteryRandomNumberConsumer, Ownable {
    enum LotteryState {
        NotInitialized,
        RegisteringVoters,
        PreparingRewards,
        RewardsDistributed,
        PreparingNewRound
    }

    struct UserVotingData {
	    uint256 lotteryPower;
    }

    Governance public TornadoGovernance;
    mapping(address => mapping(uint256 => UserVotingData)) public idToUserVotingData;
    address[][] public votersForProposal;

    constructor(address _governance) public LotteryRandomNumberConsumer() {
        TornadoGovernance = Governance(_governance);
    }

    function _registerAccountWithLottery(uint256 proposalId) internal {
	    require(_checkIfAccountHasVoted(msg.sender, proposalId), "Account has not voted on this proposal");
	    votersForProposal[proposalId][votersForProposal.length] = msg.sender;
    }

    function _checkIfAccountHasVoted(address account, uint256 proposalId) internal view returns (bool) {
	    return Governance.proposals[proposalId].receipts[account].hasVoted;
    }

    function _calculateSquareRoot(uint256 number) internal returns (uint256);

    function _calculateLotteryPower(address account, uint256 proposalId) internal;
}
