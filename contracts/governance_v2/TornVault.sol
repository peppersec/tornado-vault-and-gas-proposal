// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { ImmutableGovernanceInformation } from "../ImmutableGovernanceInformation.sol";

/// @title Vault which holds user funds
contract TornVault is ImmutableGovernanceInformation {
  using SafeERC20 for IERC20;

  bool public balancesMigrated;

  /// @notice withdraws TORN from the contract
  /// @param amount amount to withdraw
  /// @return returns true on success
  function withdrawTorn(uint256 amount) external onlyGovernance returns (bool) {
    IERC20(TornTokenAddress).safeTransfer(GovernanceAddress, amount);
    return true;
  }

  /// @notice set balances to migrated
  function setBalancesMigrated() external onlyGovernance {
    require(!balancesMigrated, "already migrated");
    balancesMigrated = true;
  }
}
