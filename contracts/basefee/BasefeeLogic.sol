// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract BasefeeLogic {
  function returnBasefee() external view returns (uint256) {
    return block.basefee;
  }
}
