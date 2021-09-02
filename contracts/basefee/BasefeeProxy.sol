// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IBasefeeLogic {
  function returnBasefee() external view returns (uint256);
}

contract BasefeeProxy {
  address public immutable logic;

  constructor(address _logic) public {
    logic = _logic;
  }

  function returnBasefee() public view returns (uint256 basefee) {
    return IBasefeeLogic(logic).returnBasefee();
  }
}
