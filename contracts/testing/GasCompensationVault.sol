// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract GasCompensationVault {
  address private constant GovernanceAddress = 0x5efda50f22d34F262c29268506C5Fa42cB56A1Ce;

  modifier onlyGovernance() {
    require(msg.sender == GovernanceAddress, "only gov");
    _;
  }

  function compensateGas(address recipient, uint256 amount) external onlyGovernance {
    if (address(this).balance == 0) return;
    require(
      (amount > address(this).balance) ? payable(recipient).send(address(this).balance) : payable(recipient).send(amount),
      "compensation failed"
    );
  }

  receive() external payable {}

  function getBasefee() external view returns (uint256) {
    return 5;
  }
}
