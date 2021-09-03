// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import { GovernanceVaultUpgrade } from "../vault/GovernanceVaultUpgrade.sol";
import { GasCompensator, IGasCompensationVault } from "../basefee/GasCompensator.sol";
import { ITornadoLottery } from "../interfaces/ITornadoLottery.sol";
import { ITornadoVault } from "../interfaces/ITornadoVault.sol";

contract GovernanceLotteryUpgrade is GovernanceVaultUpgrade, GasCompensator {
  ITornadoLottery public immutable lottery;
  address public immutable multisigAddress;

  event RegisterAccountReverted(uint256 proposalId, address account);

  constructor(
    address _gasCompLogic,
    ITornadoLottery _lotteryLogic,
    ITornadoVault _userVault,
    address _multisigAddress
  ) public GovernanceVaultUpgrade(_userVault) GasCompensator(_gasCompLogic) {
    lottery = _lotteryLogic;
    multisigAddress = _multisigAddress;
  }

  modifier onlyMultisig() {
    require(msg.sender == multisigAddress, "only multisig");
    _;
  }

  function setGasCompensations(uint256 _gasCompensationsLimit) external virtual override onlyMultisig {
    require(
      (_gasCompensationsLimit > address(this).balance)
        ? payable(address(gasCompensationLogic)).send(address(this).balance)
        : payable(address(gasCompensationLogic)).send(_gasCompensationsLimit),
      "send failed"
    );
  }

  function withdrawFromHelper(uint256 amount) external virtual override onlyMultisig {
    IGasCompensationVault(gasCompensationLogic).withdrawToGovernance(amount);
  }

  function receiveEther() external payable virtual returns (bool) {
    return true;
  } // receive doesn't work with proxy for some reason

  function castVote(uint256 proposalId, bool support)
    external
    virtual
    override
    gasCompensation(msg.sender, !hasAccountVoted(proposalId, msg.sender), (msg.sender == tx.origin ? 21e3 : 0))
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
  )
    external
    virtual
    override
    gasCompensation(
      msg.sender,
      !hasAccountVoted(proposalId, msg.sender),
      (msg.sender == tx.origin ? (lockedBalance[msg.sender] > 0 ? 21e3 : 20e3) : 0)
    )
  {
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
      lottery.registerAccountWithLottery(
        proposalId,
        account,
        uint96(proposals[proposalId].receipts[account].votes)
      )
    {} catch {
      emit RegisterAccountReverted(proposalId, account);
    }
  }
}
