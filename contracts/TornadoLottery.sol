pragma solidity ^0.6.12;

import {Governance} from "../tornado-governance/contracts/Governance.sol";

contract TornadoLottery {
    Governance public TornadoGovernance;

    constructor(address _governance) {
        TornadoGovernance = Governance(_governance);
    }
}
