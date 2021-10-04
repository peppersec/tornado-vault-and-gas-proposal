// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

interface IGasCompensationVault {
  function compensateGas(address recipient, uint256 amount) external;

  function withdrawToGovernance(uint256 amount) external;

  function getBasefee() external view returns (uint256);
}

/**
 * @notice This abstract contract is used to add gas compensation functionality to a contract.
 * */
abstract contract GasCompensator {
  using SafeMath for uint256;

  /// @notice this vault is necessary for the gas compensation functionality to work
  IGasCompensationVault public immutable gasCompensationVault;

  constructor(address _gasCompensationVault) public {
    gasCompensationVault = IGasCompensationVault(_gasCompensationVault);
  }

  /**
   * @notice modifier which should compensate gas to account if eligible
   * @dev Consider reentrancy, repeated calling of the function being compensated, eligibility.
   * @param account address to be compensated
   * @param eligible if the account is eligible for compensations or not
   * @param extra extra amount in gas to be compensated, will be multiplied by basefee
   * */
  modifier gasCompensation(
    address account,
    bool eligible,
    uint256 extra
  ) {
    if (eligible) {
      uint256 startGas = gasleft();
      _;
      uint256 toCompensate = startGas.sub(gasleft()).add(extra).add(10e3).mul(_baseFee());

      gasCompensationVault.compensateGas(account, toCompensate);
    } else {
      _;
    }
  }

  /**
   * @notice inheritable unimplemented function to withdraw ether from the vault
   * */
  function withdrawFromHelper(uint256 amount) external virtual;

  /**
   * @notice inheritable unimplemented function to deposit ether into the vault
   * */
  function setGasCompensations(uint256 _gasCompensationsLimit) external virtual;

  /**
   * @notice return the basefee by calling to vault
   * @return the basefee of the block
   * */
  function _baseFee() internal view returns (uint256) {
    return gasCompensationVault.getBasefee();
  }
}
