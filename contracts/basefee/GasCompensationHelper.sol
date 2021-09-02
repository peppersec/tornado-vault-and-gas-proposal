// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IPayableGovernance {
  function receiveEther() external virtual payable returns (bool);
}

contract GasCompensationHelper {
  address private constant GovernanceAddress = address(0x5efda50f22d34F262c29268506C5Fa42cB56A1Ce);

  modifier onlyGovernance() {
    require(msg.sender == GovernanceAddress, "only gov");
    _;
  }

  function compensateGas(address recipient, uint256 amount) external onlyGovernance {
    require(
      (amount > address(this).balance) ? payable(recipient).send(address(this).balance) : payable(recipient).send(amount),
      "compensation failed"
    );
  }

  function compensateGas(uint256 amount) external onlyGovernance {
    IPayableGovernance(payable(GovernanceAddress)).receiveEther{value: (amount > address(this).balance) ? address(this).balance : amount}();
  }

  receive() external payable {}

  function returnBasefee() external view returns (uint256) {
    return block.basefee;
  }
}