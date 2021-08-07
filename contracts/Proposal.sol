// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import {Governance} from "../tornado-governance/contracts/Governance.sol";

contract Proposal {
    address public constant GovernanceAddress =
        address(0x5efda50f22d34F262c29268506C5Fa42cB56A1Ce);
    uint256 public votingPeriod;

    constructor(uint256 _votingPeriod) public {
        votingPeriod = _votingPeriod;
    }

    function executeProposal() external {
        // 1st part of proposal - set the voting period.
        Governance gov = Governance(GovernanceAddress);
        gov.setVotingPeriod(votingPeriod);
    }
}
