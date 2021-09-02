// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { BASEFEE_PROXY } from "./BASEFEE_PROXY.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

abstract contract GasCompensator is BASEFEE_PROXY {
  using SafeMath for uint256;

  bool public gasCompensationsPaused;
  uint256 public gasCompensationsLimit;

  constructor(address _logic) public BASEFEE_PROXY(_logic) {}

  modifier gasCompensation(
    address account,
    bool eligible,
    uint256 extra
  ) {
    if (!gasCompensationsPaused && eligible) {
      uint256 startGas = gasleft();
      _;
      uint256 toCompensate = startGas.sub(gasleft()).add(extra).mul(RETURN_BASEFEE());

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
