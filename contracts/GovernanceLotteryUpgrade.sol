// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import { GovernanceV2 } from "./governance_v2/GovernanceV2.sol";
import { GasCompensator } from "./basefee/GasCompensator.sol";
import { ITornadoLottery } from "./interfaces/ITornadoLottery.sol";

contract GovernanceLotteryUpgrade is GovernanceV2, GasCompensator {
  address public constant TornadoMultisig = address(0xb04E030140b30C27bcdfaafFFA98C57d80eDa7B4);
  address public immutable lotteryAddress;

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

  function setGasCompensations(bool _paused) external virtual override onlyMultisig {
    gasCompensationsPaused = _paused;
  }

  function castVote(uint256 proposalId, bool support)
    external
    virtual
    override
    gasCompensation(msg.sender, !hasAccountVoted(proposalId, msg.sender), 21000)
  {
    bool votedAlready = hasAccountVoted(proposalId, msg.sender);
    _castVote(msg.sender, proposalId, support);
    if (!votedAlready) {
      _registerAccountWithLottery(proposalId, msg.sender);
    }
  }

  function castDelegatedVote(
    address[] memory from,
    uint256 proposalId,
    bool support
  ) external virtual override gasCompensation(msg.sender, !hasAccountVoted(proposalId, msg.sender), 0) {
    for (uint256 i = 0; i < from.length; i++) {
      require(delegatedTo[from[i]] == msg.sender, "Governance: not authorized");
      bool votedAlready = hasAccountVoted(proposalId, from[i]);
      _castVote(from[i], proposalId, support);
      if (!votedAlready) {
        _registerAccountWithLottery(proposalId, from[i]);
      }
    }
    if (lockedBalance[msg.sender] > 0) {
      bool votedAlready = hasAccountVoted(proposalId, msg.sender);
      _castVote(msg.sender, proposalId, support);
      if (!votedAlready) {
        _registerAccountWithLottery(proposalId, msg.sender);
      }
    }
  }

  /// @notice checker for success on deployment
  /// @return returns precise version of governance
  function version() external pure virtual override returns (string memory) {
    return "2.lottery-and-vault-upgrade";
  }

  function hasAccountVoted(uint256 proposalId, address account) public view returns (bool) {
    return proposals[proposalId].receipts[account].hasVoted;
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
