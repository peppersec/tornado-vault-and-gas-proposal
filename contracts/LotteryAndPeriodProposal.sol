// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { TornadoLottery } from "./TornadoLottery.sol";
import { TornVault } from "./governance_v2/TornVault.sol";
import { GovernanceLotteryUpgrade } from "./GovernanceLotteryUpgrade.sol";
import { TornadoAuctionHandler } from "./auction/TornadoAuctionHandler.sol";
import { LoopbackProxy } from "../tornado-governance/contracts/LoopbackProxy.sol";
import { ImmutableGovernanceInformation } from "./proposal/ImmutableGovernanceInformation.sol";

contract LotteryAndPeriodProposal is ImmutableGovernanceInformation {
  address public immutable basefeeLogic;
  uint256 public immutable votingPeriod;

  constructor(address _basefeeLogic, uint256 _votingPeriod) public {
    basefeeLogic = _basefeeLogic;
    votingPeriod = _votingPeriod;
  }

  function executeProposal() external {
    address lottery = address(new TornadoLottery());
    address vault = address(new TornVault());

    LoopbackProxy(returnPayableGovernance()).upgradeTo(address(new GovernanceLotteryUpgrade(basefeeLogic, lottery, vault)));
    GovernanceLotteryUpgrade(returnPayableGovernance()).setVotingPeriod(votingPeriod);
    IERC20(TornTokenAddress).approve(lottery, type(uint256).max);

    TornadoAuctionHandler auctionHandler = new TornadoAuctionHandler();
    IERC20(TornTokenAddress).transfer(address(auctionHandler), 100e18);
    // EXAMPLE NUMBERS
    auctionHandler.initializeAuction(1631743200, 100 ether, 151e16, 1 ether, 0);
  }
}
