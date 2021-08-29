// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {GovernanceLotteryUpgrade} from "./GovernanceLotteryUpgrade.sol";
import {TornadoAuctionHandler} from "./auction/TornadoAuctionHandler.sol";
import {LotteryProposalExtrasHelper} from "./proposal/LotteryProposalExtrasHelper.sol";
import {LotteryProposalUpgradesHelper} from "./proposal/LotteryProposalUpgradesHelper.sol";
import {ImmutableGovernanceInformation} from "./proposal/ImmutableGovernanceInformation.sol";

contract LotteryAndPeriodProposal is ImmutableGovernanceInformation {
    address public immutable ProposalUpgradesHelperAddress;
    address public immutable ProposalUpgradesExtrasAddress;

    constructor(
        address _ProposalUpgradesHelperAddress,
        address _ProposalUpgradesExtrasAddress
    ) public {
        ProposalUpgradesHelperAddress = _ProposalUpgradesHelperAddress;
        ProposalUpgradesExtrasAddress = _ProposalUpgradesExtrasAddress;
    }

    function executeProposal() external {
        (bool success, ) = ProposalUpgradesHelperAddress.delegatecall(
            abi.encodeWithSignature("nestedUpgradeGovernance()")
        );
        require(success, "upgrade failed");

        (success, ) = ProposalUpgradesExtrasAddress.delegatecall(
            abi.encodeWithSignature("nestedFunctionsGovernance()")
        );
        require(success, "functions failed");

        TornadoAuctionHandler auctionStarter = new TornadoAuctionHandler();
        IERC20(TornTokenAddress).transfer(address(auctionStarter), 100e18);

        // EXAMPLE NUMBERS
        auctionStarter.initializeAuction(
            1631743200,
            100 ether,
            151e16,
            10 ether,
            0
        );
    }
}
