// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12 || ^0.8.7;

library EtherSend {
  function sendEther(
    address to,
    uint256 amount
  ) internal returns (bool success) {
    (success, ) = payable(to).call{ value: amount }("");
  }
}
