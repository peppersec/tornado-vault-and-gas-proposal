// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

interface IGasCompensationHelper {
  function compensateGas(address recipient, uint256 amount) external;
  function withdrawToGovernance(uint256 amount) external;
  function getBasefee() external view returns (uint256);
}

abstract contract GasCompensator {
  using SafeMath for uint256;

  IGasCompensationHelper public immutable gasCompensationLogic;

  constructor(address _gasCompensationLogic) public {
    gasCompensationLogic = IGasCompensationHelper(_gasCompensationLogic);
  }

  modifier gasCompensation(
    address account,
    bool eligible,
    uint256 extra
  ) {
    if (eligible) {
      uint256 startGas = gasleft();
      _;
      uint256 toCompensate = startGas.sub(gasleft()).add(extra).add(10e3).mul(returnBasefee());

      gasCompensationLogic.compensateGas(account, toCompensate);
    } else {
      _;
    }
  }

  function withdrawFromHelper(uint256 amount) external virtual;

  function setGasCompensations(uint256 _gasCompensationsLimit) external virtual;

  function returnBasefee() internal view returns (uint256) {
    return gasCompensationLogic.getBasefee();
  }
}
