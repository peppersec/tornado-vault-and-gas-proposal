// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {ProposalUpgradesHelperBase} from "./ProposalUpgradesHelperBase.sol";
import {GovernanceLotteryUpgrade} from "../GovernanceLotteryUpgrade.sol";

contract LotteryProposalUpgradesHelper is ProposalUpgradesHelperBase {
    address public immutable basefeeLogic;

    constructor(address _basefeeLogic) public {
        basefeeLogic = _basefeeLogic;
    }

    function nestedUpgradeGovernance() external virtual override {
        GovernanceLotteryUpgrade newGovernanceContract = GovernanceLotteryUpgrade(
                upgradeGovernanceLogicAndReturnAddress(
                    constructUpgradedGovernance(basefeeLogic)
                )
            ); // basefeeLogic is stored in an immutable variable in BASEFEE_PROXY
    }

    function constructUpgradedGovernance(address _basefeeLogic)
        public
        returns (GovernanceLotteryUpgrade)
    {
        return new GovernanceLotteryUpgrade(_basefeeLogic);
    }
}