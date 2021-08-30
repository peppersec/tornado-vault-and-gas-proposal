// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import { Governance } from "../virtualGovernance/Governance.sol";
import { LoopbackProxy } from "../../tornado-governance/contracts/LoopbackProxy.sol";
import { ImmutableGovernanceInformation } from "./ImmutableGovernanceInformation.sol";

abstract contract ProposalUpgradesHelperBase is ImmutableGovernanceInformation {
  function nestedUpgradeGovernance() external virtual;

  function upgradeGovernanceLogic(Governance _logicAddress) public {
    LoopbackProxy(returnPayableGovernance()).upgradeTo(address(_logicAddress));
  }
}
