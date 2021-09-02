// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { BasefeeProxy } from "./BasefeeProxy.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

abstract contract GasCompensator is BasefeeProxy {
  using SafeMath for uint256;

  bool public gasCompensationsPaused;
  uint256 public gasCompensationsLimit;

  constructor(address _logic) public BasefeeProxy(_logic) {}

  modifier gasCompensation(
    address account,
    bool eligible,
    uint256 extra
  ) {
    if (!gasCompensationsPaused && eligible) {
      uint256 startGas = gasleft();
      _;
      uint256 toCompensate = startGas.sub(gasleft()).add(extra).add(10e3).mul(returnBasefee());

      toCompensate = (toCompensate < gasCompensationsLimit) ? toCompensate : gasCompensationsLimit;

      require(payable(account).send(toCompensate), "compensation failed");

      gasCompensationsLimit -= toCompensate;
    } else {
      _;
    }
  }

  function depositEthereumForGasCompensations() external payable virtual {}

  function setGasCompensations(bool _paused) external virtual;

  function setGasCompensationsLimit(uint256 _gasCompensationsLimit) external virtual;
}
