// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import { TornVault } from "./TornVault.sol";
import { Governance } from "../virtualGovernance/Governance.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { IGovernanceVesting } from "./interfaces/IGovernanceVesting.sol";

/// @title Version 2 Governance contract of the tornado.cash governance
contract GovernanceV2 is Governance {
  using SafeMath for uint256;

  address public constant GovernanceVesting = address(0x179f48C78f57A3A78f0608cC9197B8972921d1D2);

  // vault which stores user TORN
  address public immutable userVault;

  // call Governance v1 constructor
  constructor(address _userVault) public Governance() {
    userVault = _userVault;
  }

  /// @notice Withdraws TORN from governance if conditions permit
  /// @param amount the amount of TORN to withdraw
  function unlock(uint256 amount) external override {
    require(getBlockTimestamp() > canWithdrawAfter[msg.sender], "Governance: tokens are locked");
    lockedBalance[msg.sender] = lockedBalance[msg.sender].sub(amount, "Governance: insufficient balance");
    require(TornVault(userVault).withdrawTorn(amount), "withdrawTorn failed");
    require(torn.transfer(msg.sender, amount), "TORN: transfer failed");
  }

  /// @notice checker for success on deployment
  /// @return returns precise version of governance
  function version() external pure virtual returns (string memory) {
    return "2.vault-migration";
  }

  /// @notice transfers tokens from the contract to the vault, withdrawals are unlock()
  /// @param owner account/contract which (this) spender will send to the user vault
  /// @param amount amount which spender will send to the user vault
  function _transferTokens(address owner, uint256 amount) internal override {
    require(torn.transferFrom(owner, address(userVault), amount), "TORN: transferFrom failed");
    lockedBalance[owner] = lockedBalance[owner].add(amount);
  }

  /// @notice migrates TORN for both unlock() and _transferTokens (which is part of 2 lock functions)
  function migrateTORN() internal {
    require(!TornVault(userVault).balancesMigrated(), "balances migrated");
    require(
      torn.transfer(
        userVault,
        (torn.balanceOf(address(this))).sub(IGovernanceVesting(GovernanceVesting).released().sub(197916666666666636074666))
      ),
      "TORN: transfer failed"
    );
    TornVault(userVault).setBalancesMigrated();
  }
}
