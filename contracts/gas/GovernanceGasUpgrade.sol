// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import { GovernanceVaultUpgrade } from "../vault/GovernanceVaultUpgrade.sol";
import { GasCompensator } from "./GasCompensator.sol";
import { Math } from "@openzeppelin/contracts/math/Math.sol";

contract GovernanceGasUpgrade is GovernanceVaultUpgrade, GasCompensator {
  constructor(address _gasCompLogic, address _userVault)
    public
    GovernanceVaultUpgrade(_userVault)
    GasCompensator(_gasCompLogic)
  {}

  modifier onlyMultisig() {
    require(msg.sender == returnMultisigAddress(), "only multisig");
    _;
  }

  receive() external payable {}

  function setGasCompensations(uint256 gasCompensationsLimit) external virtual override onlyMultisig {
    require(payable(address(gasCompensationVault)).send(Math.min(gasCompensationsLimit, address(this).balance)));
  }

  function withdrawFromHelper(uint256 amount) external virtual override onlyMultisig {
    gasCompensationVault.withdrawToGovernance(amount);
  }

  function castVote(uint256 proposalId, bool support)
    external
    virtual
    override
    gasCompensation(
      msg.sender,
      !hasAccountVoted(proposalId, msg.sender) && !checkIfQuorumReached(proposalId),
      (msg.sender == tx.origin ? 21e3 : 0)
    )
  {
    _castVote(msg.sender, proposalId, support);
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
      !hasAccountVoted(proposalId, msg.sender) && !checkIfQuorumReached(proposalId),
      (msg.sender == tx.origin ? 21e3 : 0)
    )
  {
    require(from.length > 0, "Can not be empty");
    for (uint256 i = 0; i < from.length; i++) {
      require(delegatedTo[from[i]] == msg.sender || from[i] == msg.sender, "Governance: not authorized");
      _castVote(from[i], proposalId, support);
    }
  }

  /// @notice checker for success on deployment
  /// @return returns precise version of governance
  function version() external pure virtual override returns (string memory) {
    return "2.lottery-and-gas-upgrade";
  }

  function checkIfQuorumReached(uint256 proposalId) public view returns (bool) {
    return (proposals[proposalId].forVotes + proposals[proposalId].againstVotes >= QUORUM_VOTES);
  }

  function hasAccountVoted(uint256 proposalId, address account) public view returns (bool) {
    return proposals[proposalId].receipts[account].hasVoted;
  }

  function returnMultisigAddress() public pure virtual returns (address) {
    return 0xb04E030140b30C27bcdfaafFFA98C57d80eDa7B4;
  }
}