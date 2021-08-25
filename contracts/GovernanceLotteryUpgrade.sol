// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {Governance} from "./virtualGovernance/Governance.sol";
import {TornadoLotteryFunctionality} from "./TornadoLotteryFunctionality.sol";
import {GasCalculator} from "./basefee/GasCalculator.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {UniswapV3TWAP} from "./univ3/UniswapV3TWAP.sol";

contract GovernanceLotteryUpgrade is
    Governance,
    TornadoLotteryFunctionality,
    GasCalculator
{
    using UniswapV3TWAP for address;

    address public constant univ3TornPool =
        address(0x753a90Ae2fA03d31487141bF54Bd853b27F7BCf5);

    mapping(address => mapping(uint256 => bool)) public compensatedForVote;

    constructor(address _logic)
        public
        Governance()
        TornadoLotteryFunctionality()
        GasCalculator(_logic)
    {}

    function prepareProposalForPayouts(
        uint256 proposalId,
        uint256 proposalRewards,
        uint256 numberOfWinners
    ) external virtual {
        require(msg.sender == TornadoMultisig, "only multisig");
        _prepareProposalForPayouts(
            proposalId,
            proposalRewards,
            numberOfWinners
        );
    }

    function setSpendableTornForGasCompensations(uint256 _gasTokenAmountInEther)
        external
        virtual
        override
    {
        require(msg.sender == TornadoMultisig, "only multisig");
        gasTokenAmountInEther = _gasTokenAmountInEther;
    }

    function pauseOrUnpauseGasCompensations() external virtual override {
        require(msg.sender == TornadoMultisig, "only multisig");
        gasCompensationsPaused = !gasCompensationsPaused;
    }

    function claimRewards(uint256 proposalId) external virtual override {
        _rollAndTransferUserForProposal(proposalId, address(torn), msg.sender);
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
        gasCompensation(voter, compensatedForVote[voter][proposalId])
    {
        compensatedForVote[voter][proposalId] = true;
        super._castVote(voter, proposalId, support);
        _errorHandledRegisterAccountWithLottery(
            proposalId,
            voter,
            proposals[proposalId].receipts[voter].votes
        );
    }

    function _compensateGasLogic(address account, uint256 amount)
        internal
        virtual
        override
    {
        uint256 toCompensate = SafeMath.div(
            SafeMath.mul(amount, 1e18),
            univ3TornPool.getTWAPFromPool(10000)
        );
        toCompensate = (toCompensate < gasTokenAmountInEther)
            ? toCompensate
            : gasTokenAmountInEther;

        require(
            torn.transfer(account, toCompensate),
            "compensation transfer failed"
        );

        gasTokenAmountInEther -= toCompensate;
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
