// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import {Governance} from "../tornado-governance/contracts/Governance.sol";

contract TornadoLottery {

    enum LotteryState {
	    NotInitialized,
	    RegisteringVoters,
	    PreparingRewards,
	    RewardsDistributed
    }

    Governance public TornadoGovernance;

    constructor(address _governance) public {
        TornadoGovernance = Governance(_governance);
    }
}
