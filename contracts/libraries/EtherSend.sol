// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12 || ^0.8.7;

library EtherSend {
  function sendEther(
    address to,
    uint256 amount,
    string memory nonExistingSignature
  ) internal returns (bool success) {
    (success, ) = payable(to).call{ value: amount }(abi.encodeWithSignature(nonExistingSignature));
  }
}
