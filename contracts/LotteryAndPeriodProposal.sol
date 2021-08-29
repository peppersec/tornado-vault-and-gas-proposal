// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {GovernanceLotteryUpgrade} from "./GovernanceLotteryUpgrade.sol";
import {TornadoAuctionHandler} from "./auction/TornadoAuctionHandler.sol";
import {ImmutableGovernanceInformation} from "./proposal/ImmutableGovernanceInformation.sol";

contract LotteryAndPeriodProposal is ImmutableGovernanceInformation {
    address public immutable UpgradesProposalHelperAddress;
    address public immutable ExtrasProposalHelperAddress;

    constructor(
        address _UpgradesProposalHelperAddress,
        address _ExtrasProposalHelperAddress
    ) public {
        UpgradesProposalHelperAddress = _UpgradesProposalHelperAddress;
        ExtrasProposalHelperAddress = _ExtrasProposalHelperAddress;
    }

    function executeProposal() external {
        (bool success, ) = UpgradesProposalHelperAddress.delegatecall(
            abi.encodeWithSignature("nestedUpgradeGovernance()")
        );
        require(success, "upgrade failed");

        (success, ) = ExtrasProposalHelperAddress.delegatecall(
            abi.encodeWithSignature("nestedFunctionsGovernance()")
        );
        require(success, "functions failed");

        TornadoAuctionHandler auctionHandler = new TornadoAuctionHandler();

        IERC20(TornTokenAddress).transfer(address(auctionHandler), 100e18);

        // EXAMPLE NUMBERS
        auctionHandler.initializeAuction(
            1631743200,
            100 ether,
            151e16,
            1 ether,
            0
        );
    }
}
