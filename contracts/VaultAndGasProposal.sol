// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { LoopbackProxy } from "tornado-governance/contracts/LoopbackProxy.sol";

import { TornadoVault } from "./vault/TornadoVault.sol";
import { TornadoAuctionHandler } from "./auction/TornadoAuctionHandler.sol";
import { GovernanceGasUpgrade } from "./gas/GovernanceGasUpgrade.sol";

import { IGovernanceVesting } from "./interfaces/IGovernanceVesting.sol";
import { ImmutableGovernanceInformation } from "./ImmutableGovernanceInformation.sol";

contract VaultAndGasProposal is ImmutableGovernanceInformation {
  using SafeMath for uint256;

  IGovernanceVesting public constant GovernanceVesting = IGovernanceVesting(0x179f48C78f57A3A78f0608cC9197B8972921d1D2);
  address public immutable gasCompLogic;
  uint256 public immutable votingPeriod;

  constructor(address _gasCompLogic, uint256 _votingPeriod) public {
    gasCompLogic = _gasCompLogic;
    votingPeriod = _votingPeriod;
  }

  function executeProposal() external {
    address vault = address(new TornadoVault());

    LoopbackProxy(returnPayableGovernance()).upgradeTo(address(new GovernanceGasUpgrade(gasCompLogic, vault)));

    GovernanceGasUpgrade newGovernance = GovernanceGasUpgrade(payable(GovernanceAddress));
    IERC20 tornToken = IERC20(TornTokenAddress);

    newGovernance.setVotingPeriod(votingPeriod);

    /**
    The below variable holds the total amount of TORN outflows from all of the proposal executions,
    which will be used to calculate the proper amount of TORN for transfer to Governance.
    For an explanation as to how this variable has been calculated with these fix values, please look at:
    https://github.com/h-ivor/tornado-lottery-period/blob/final_with_auction/scripts/balance_estimation.md
    */
    uint256 totalOutflowsOfProposalExecutions = 120000000000000000000000 + 22916666666666666666666 + 54999999999999969408000 - 27e18;

    require(
      tornToken.transfer(
        address(newGovernance.userVault()),
        (tornToken.balanceOf(address(this))).sub(GovernanceVesting.released().sub(totalOutflowsOfProposalExecutions))
      ),
      "TORN: transfer failed"
    );

    uint256 amountOfTornToAuctionOff = 100 ether;

    TornadoAuctionHandler auctionHandler = new TornadoAuctionHandler();
    tornToken.transfer(address(auctionHandler), amountOfTornToAuctionOff);

    /**
    As with above, please see:
    https://github.com/h-ivor/tornado-lottery-period/blob/final_with_auction/contracts/auction/Auction.md
    */
    auctionHandler.initializeAuction(block.timestamp + 5 days, uint96(amountOfTornToAuctionOff), 151e16, 0.1 ether, 0);
  }
}
