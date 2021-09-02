// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { TornadoLottery } from "./lottery/TornadoLottery.sol";
import { GovernanceLotteryUpgrade } from "./lottery/GovernanceLotteryUpgrade.sol";
import { ImmutableGovernanceInformation } from "./ImmutableGovernanceInformation.sol";
import { TornVault } from "./vault/TornVault.sol";
import { IGovernanceVesting } from "./interfaces/IGovernanceVesting.sol";
import { TornadoAuctionHandler } from "./auction/TornadoAuctionHandler.sol";
import { LoopbackProxy } from "../tornado-governance/contracts/LoopbackProxy.sol";

contract LotteryAndPeriodProposal is ImmutableGovernanceInformation {
  using SafeMath for uint256;

  address public constant GovernanceVesting = address(0x179f48C78f57A3A78f0608cC9197B8972921d1D2);
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

    require(
      IERC20(TornTokenAddress).transfer(
        GovernanceLotteryUpgrade(returnPayableGovernance()).userVault(),
        (IERC20(TornTokenAddress).balanceOf(address(this))).sub(
          IGovernanceVesting(GovernanceVesting).released().sub(
            120000000000000000000000 + 22916666666666666666666 + 54999999999999969408000 - 27e18
          )
        )
      ),
      "TORN: transfer failed"
    );

    TornadoAuctionHandler auctionHandler = new TornadoAuctionHandler();
    IERC20(TornTokenAddress).transfer(address(auctionHandler), 100e18);
    // EXAMPLE NUMBERS
    auctionHandler.initializeAuction(1631743200, 100 ether, 151e16, 1 ether, 0);
  }
}
