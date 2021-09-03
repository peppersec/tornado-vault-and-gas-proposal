// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

contract ImmutableGovernanceInformation {
  address internal constant TornadoMultisig = 0xb04E030140b30C27bcdfaafFFA98C57d80eDa7B4;
  address internal constant GovernanceAddress = 0x5efda50f22d34F262c29268506C5Fa42cB56A1Ce;
  address internal constant TornTokenAddress = 0x77777FeDdddFfC19Ff86DB637967013e6C6A116C;

  modifier onlyGovernance() {
    require(msg.sender == GovernanceAddress, "only governance");
    _;
  }

  modifier onlyMultisig() {
    require(msg.sender == TornadoMultisig, "only multisig");
    _;
  }

  function returnPayableGovernance() internal pure returns (address payable) {
    return payable(GovernanceAddress);
  }
}
