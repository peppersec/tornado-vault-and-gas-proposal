// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import { GovernanceV2 } from "./governance_v2/GovernanceV2.sol";
import { GasCompensator } from "./basefee/GasCompensator.sol";
import { ITornadoLottery } from "./interfaces/ITornadoLottery.sol";

contract GovernanceLotteryUpgrade is GovernanceV2, GasCompensator {
  address public constant TornadoMultisig = address(0xb04E030140b30C27bcdfaafFFA98C57d80eDa7B4);
  address public immutable lotteryAddress;

  mapping(address => mapping(uint256 => bool)) public compensatedForVote;

  event RegisterAccountReverted(uint256 proposalId, address account);

  constructor(
    address _basefeeLogic,
    address _lotteryLogic,
    address _userVault
  ) public GovernanceV2(_userVault) GasCompensator(_basefeeLogic) {
    lotteryAddress = _lotteryLogic;
  }

  modifier onlyMultisig() {
    require(msg.sender == TornadoMultisig, "only multisig");
    _;
  }

  function setGasCompensationsLimit(uint256 _gasCompensationsLimit) external virtual override onlyMultisig {
    gasCompensationsLimit = _gasCompensationsLimit;
  }

  function pauseOrUnpauseGasCompensations() external virtual override onlyMultisig {
    gasCompensationsPaused = !gasCompensationsPaused;
  }

  function castDelegatedVote(
    address[] memory from,
    uint256 proposalId,
    bool support
  ) external virtual override gasCompensation(msg.sender, !compensatedForVote[msg.sender][proposalId], 0) {
    compensatedForVote[msg.sender][proposalId] = true;
    for (uint256 i = 0; i < from.length; i++) {
      require(delegatedTo[from[i]] == msg.sender, "Governance: not authorized");
      super._castVote(from[i], proposalId, support);
      _registerAccountWithLottery(proposalId, from[i]);
    }
    if (lockedBalance[msg.sender] > 0) {
      super._castVote(msg.sender, proposalId, support);
      _registerAccountWithLottery(proposalId, msg.sender);
    }
  }

  function hasAccountVoted(uint256 proposalId, address account) external view returns (bool) {
    return proposals[proposalId].receipts[account].hasVoted;
  }

  /// @notice checker for success on deployment
  /// @return returns precise version of governance
  function version() external pure virtual override returns (string memory) {
    return "2.lottery-and-vault-upgrade";
  }

  function _castVote(
    address voter,
    uint256 proposalId,
    bool support
  ) internal virtual override gasCompensation(voter, !compensatedForVote[voter][proposalId], 210000) {
    compensatedForVote[voter][proposalId] = true;
    super._castVote(voter, proposalId, support);
    _registerAccountWithLottery(proposalId, voter);
  }

  function _registerAccountWithLottery(uint256 proposalId, address account) private {
    try
      ITornadoLottery(lotteryAddress).registerAccountWithLottery(
        proposalId,
        account,
        uint96(proposals[proposalId].receipts[account].votes)
      )
    {} catch {
      emit RegisterAccountReverted(proposalId, account);
    }
  }
}
