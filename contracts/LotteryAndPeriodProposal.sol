// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {GovernanceLotteryUpgrade} from "./GovernanceLotteryUpgrade.sol";
import {ProposalLibrary} from "./libraries/ProposalLibrary.sol";
import {LotteryProposalSpecific} from "./libraries/LotteryProposalSpecific.sol";
import {TornadoAuctionHandler} from "./auction/TornadoAuctionHandler.sol";

contract LotteryAndPeriodProposal {
    using ProposalLibrary for GovernanceLotteryUpgrade;

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
        GovernanceLotteryUpgrade newGovernanceContract = GovernanceLotteryUpgrade(
                (new GovernanceLotteryUpgrade(basefeeLogic))
                    .upgradeGovernanceLogicAndReturnAddress(GovernanceAddress)
            ); // basefeeLogic is stored in an immutable variable in BASEFEE_PROXY

        newGovernanceContract.runCodesAndRevertOnFail(LotteryProposalSpecific.enpackSetupCodes(votingPeriod));
        newGovernanceContract.compareValuesWithCodesAndRevertOnFail(
            LotteryProposalSpecific.enpackCheckCodes(),
            LotteryProposalSpecific.enpackCheckArgs(votingPeriod, TornadoMultisig)
        );

        TornadoAuctionHandler auctionStarter = new TornadoAuctionHandler();
        IERC20(newGovernanceContract.torn()).transfer(
            address(auctionStarter),
            100e18
        );

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
