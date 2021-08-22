// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {Governance} from "./virtualGovernance/Governance.sol";
import {TornadoLotteryFunctionality} from "./TornadoLotteryFunctionality.sol";
import {GasCalculator} from "./basefee/GasCalculator.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

contract GovernanceLotteryUpgrade is
    Governance,
    TornadoLotteryFunctionality,
    GasCalculator
{
    mapping(address => mapping(uint256 => uint256))
        public gasCompensationsForProposalInEth;
    mapping(uint256 => uint256) public tornPriceForProposal;

    constructor(address _logic)
        public
        Governance()
        TornadoLotteryFunctionality()
        GasCalculator(_logic)
    {}

    function castVoteLogic(
        address voter,
        uint256 proposalId,
        bool support
    ) external {
        require(
            msg.sender == address(this),
            "only governance may call this function"
        );
        super._castVote(voter, proposalId, support);
        _errorHandledRegisterAccountWithLottery(
            proposalId,
            voter,
            proposals[proposalId].receipts[voter].votes
        );
    }

    function castDelegatedVoteLogic(
        address sender,
        address[] memory from,
        uint256 proposalId,
        bool support
    ) external {
        require(msg.sender == address(this), "only gov can call this");
        for (uint256 i = 0; i < from.length; i++) {
            require(
                delegatedTo[from[i]] == sender,
                "Governance: not authorized"
            );
            this.castVoteLogic(from[i], proposalId, support);
        }
        if (lockedBalance[sender] > 0) {
            _castVote(sender, proposalId, support);
        }
    }

    function whitelistProposal(
        uint256 proposalId,
        uint256 proposalRewards,
        uint256 rewardRoundTimeDifference
    ) external {
        require(msg.sender == TornadoMultisig, "only multisig");
        _whitelistProposal(
            proposalId,
            address(torn),
            proposalRewards,
            rewardRoundTimeDifference
        );
    }

    function prepareProposalForPayouts(
        uint256 proposalId,
        uint256 tornPriceInEth
    ) external {
        require(msg.sender == TornadoMultisig, "only multisig");
        _prepareProposalForPayouts(proposalId);
        _setTornPriceForProposal(proposalId, tornPriceInEth);
    }

    function castDelegatedVote(
        address[] memory from,
        uint256 proposalId,
        bool support
    ) external virtual override {
        uint256 toBeCompensated = _calcApproxEthUsedForTxNoPriorityFee(
            address(this),
            abi.encodeWithSignature(
                "castDelegatedVoteLogic(address,address[],uint256,bool)",
                msg.sender,
                from,
                proposalId,
                support
            )
        );
        gasCompensationsForProposalInEth[msg.sender][
            proposalId
        ] = toBeCompensated;
    }

    /// @notice checker for success on deployment
    /// @return returns precise version of governance
    function version() external pure virtual returns (string memory) {
        return "2.lottery-upgrade";
    }

    function rollAndTransferUserForProposal(uint256 proposalId) external {
        _rollAndTransferUserForProposal(proposalId, address(torn), msg.sender);
        _compensateGas(proposalId, msg.sender);
    }

    function _compensateGas(uint256 proposalId, address account) internal {
        require(
            torn.transfer(
                account,
                SafeMath.div(
                    gasCompensationsForProposalInEth[account][proposalId],
                    tornPriceForProposal[proposalId]
                )
            ),
            "compensation transfer failed"
        );
    }

    function _setTornPriceForProposal(
        uint256 proposalId,
        uint256 tornPriceInEth
    ) internal {
        tornPriceForProposal[proposalId] = tornPriceInEth;
    }

    function _castVote(
        address voter,
        uint256 proposalId,
        bool support
    ) internal virtual override(Governance) {
        uint256 toBeCompensated = _calcApproxEthUsedForTxNoPriorityFee(
            address(this),
            abi.encodeWithSignature(
                "castVoteLogic(address,uint256,bool)",
                voter,
                proposalId,
                support
            )
        );
        gasCompensationsForProposalInEth[voter][proposalId] = toBeCompensated;
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
}
