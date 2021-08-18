// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import {Governance} from "../tornado-governance/contracts/Governance.sol";
import {GovernanceLotteryUpgrade} from "./GovernanceLotteryUpgrade.sol";
import {LoopbackProxy} from "../tornado-governance/contracts/LoopbackProxy.sol";

contract LotteryAndPeriodProposal {
    address public constant GovernanceAddress =
        address(0x5efda50f22d34F262c29268506C5Fa42cB56A1Ce);
    uint256 public immutable votingPeriod;

    constructor(uint256 _votingPeriod) public {
        votingPeriod = _votingPeriod;
    }

    function executeProposal() external {
        // 1st part of proposal - set the voting period.
        GovernanceLotteryUpgrade newGovernanceContract = new GovernanceLotteryUpgrade();

        LoopbackProxy(payable(address(this))).upgradeTo(
            address(newGovernanceContract)
        );

        newGovernanceContract = GovernanceLotteryUpgrade(
            payable(address(this))
        );

        require(
            stringCompare(newGovernanceContract.version(), "2.lottery-upgrade"),
            "Something went wrong after proxy logic upgrade failed!"
        );

        newGovernanceContract.setVotingPeriod(votingPeriod);

        require(
            newGovernanceContract.VOTING_PERIOD() == votingPeriod,
            "Voting period change failed!"
        );
    }

    /// @notice This function compares two strings by hashing them to comparable format
    /// @param a first string to compare
    /// @param b second string to compare
    /// @return true if a == b, false otherwise
    function stringCompare(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }
}
