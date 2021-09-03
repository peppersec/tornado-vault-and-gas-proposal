// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import { GovernanceVaultUpgrade } from "../vault/GovernanceVaultUpgrade.sol";
import { GasCompensator, IGasCompensationHelper } from "../basefee/GasCompensator.sol";
import { ITornadoLottery } from "../interfaces/ITornadoLottery.sol";

contract GovernanceLotteryUpgrade is GovernanceVaultUpgrade, GasCompensator {
  address public immutable lotteryAddress;

  event RegisterAccountReverted(uint256 proposalId, address account);

  constructor(
    address _gasCompLogic,
    address _lotteryLogic,
    address _userVault
  ) public GovernanceVaultUpgrade(_userVault) GasCompensator(_gasCompLogic) {
    lotteryAddress = _lotteryLogic;
  }

  modifier onlyMultisig() {
    require(msg.sender == returnMultisigAddress(), "only multisig");
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
    IGasCompensationHelper(gasCompensationLogic).withdrawToGovernance(amount);
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

  function returnMultisigAddress() internal pure virtual returns (address) {
    return address(0xb04E030140b30C27bcdfaafFFA98C57d80eDa7B4);
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
