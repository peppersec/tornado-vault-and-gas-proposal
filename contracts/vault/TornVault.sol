// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { ImmutableGovernanceInformation } from "../ImmutableGovernanceInformation.sol";

/// @title Vault which holds user funds
contract TornVault is ImmutableGovernanceInformation {
  using SafeERC20 for IERC20;

  /// @notice withdraws TORN from the contract
  /// @param amount amount to withdraw
  function withdrawTorn(address recipient, uint256 amount) external onlyGovernance {
    IERC20(TornTokenAddress).safeTransfer(recipient, amount);
  }
}
