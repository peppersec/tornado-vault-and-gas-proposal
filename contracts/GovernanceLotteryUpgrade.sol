// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {Governance} from "./virtualGovernance/Governance.sol";
import {GasCalculator} from "./basefee/GasCalculator.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {TornadoLottery} from "./TornadoLottery";

import "hardhat/console.sol";

contract GovernanceLotteryUpgrade is
    Governance,
    GasCalculator
{
    mapping(address => mapping(uint256 => bool)) public compensatedForVote;
    TornadoLottery public GovernanceLottery;

    constructor(address _logic)
        public
        Governance()
        GasCalculator(_logic)
    {}

    function deployLottery() external returns (bool) {
        require(address(GovernanceLottery) == address(0), "vault already deployed");
	GovernanceLottery = new TornadoLottery();
        assert(address(GovernanceLottery) != address(0));
	torn.approve(address(GovernanceLottery), type(uint256).max);
	return true;
    }

    function prepareProposalForPayouts(
        uint256 proposalId,
        uint256 proposalRewards,
        uint256 numberOfWinners
    ) external virtual {
        require(msg.sender == TornadoMultisig, "only multisig");
        GovernanceLottery._prepareProposalForPayouts(
            proposalId,
            proposalRewards
        );
    }

    function setGasCompensationsLimit(uint256 _gasCompensationsLimit)
        external
        virtual
        override
    {
        require(msg.sender == TornadoMultisig, "only multisig");
        gasCompensationsLimit = _gasCompensationsLimit;
    }

    function pauseOrUnpauseGasCompensations() external virtual override {
        require(msg.sender == TornadoMultisig, "only multisig");
        gasCompensationsPaused = !gasCompensationsPaused;
    }

    function castDelegatedVote(
        address[] memory from,
        uint256 proposalId,
        bool support
    ) external virtual override gasCompensation(voter, !compensatedForVote[voter][proposalId], 0) {
        compensatedForVote[voter][proposalId] = true;
        for (uint256 i = 0; i < from.length; i++) {
            require(
                delegatedTo[from[i]] == msg.sender,
                "Governance: not authorized"
            );
            super._castVote(from[i], proposalId, support);
        }
        if (lockedBalance[msg.sender] > 0) {
            super._castVote(msg.sender, proposalId, support);
        }
    }

    function claimRewards(uint256 proposalId) external virtual override {
        GovernanceLottery.claimRewards(proposalId, address(torn), msg.sender);
    }

    /// @notice checker for success on deployment
    /// @return returns precise version of governance
    function version() external pure virtual returns (string memory) {
        return "2.lottery-upgrade";
    }

    function _castVote(
        address voter,
        uint256 proposalId,
        bool support
    )
        internal
        virtual
        override
        gasCompensation(voter, !compensatedForVote[voter][proposalId], 0)
    {
        compensatedForVote[voter][proposalId] = true;
        super._castVote(voter, proposalId, support);
        _errorHandledRegisterAccountWithLottery(
            proposalId,
            voter,
            proposals[proposalId].receipts[voter].votes
        );
    }
}
