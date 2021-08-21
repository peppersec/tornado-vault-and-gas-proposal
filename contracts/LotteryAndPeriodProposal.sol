// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import {GovernanceLotteryUpgrade} from "./GovernanceLotteryUpgrade.sol";
import {LoopbackProxy} from "../tornado-governance/contracts/LoopbackProxy.sol";

contract LotteryAndPeriodProposal {
    address public constant GovernanceAddress =
        address(0x5efda50f22d34F262c29268506C5Fa42cB56A1Ce);
    address public constant TornadoMultisig =
        address(0xb04E030140b30C27bcdfaafFFA98C57d80eDa7B4);
    address public immutable basefeeLogic;
    uint256 public immutable votingPeriod;

    constructor(uint256 _votingPeriod, address _basefeeLogic) public {
        votingPeriod = _votingPeriod;
        basefeeLogic = _basefeeLogic;
    }

    function executeProposal() external {
        GovernanceLotteryUpgrade newGovernanceContract = new GovernanceLotteryUpgrade(
                basefeeLogic
            ); // basefeeLogic is stored in an immutable variable in BASEFEE_PROXY

        LoopbackProxy(payable(address(this))).upgradeTo(
            address(newGovernanceContract)
        );

        newGovernanceContract = GovernanceLotteryUpgrade(
            payable(address(this))
        );

        require(
            newGovernanceContract.TornadoMultisig() == TornadoMultisig,
            "Multisig address wrong"
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
        private
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }
}
