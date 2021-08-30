// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { IWETH } from "./interfaces/IWETH.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IEasyAuction } from "./interfaces/IEasyAuction.sol";
import { IGovernanceDepositInterface } from "./interfaces/IGovernanceDepositInterface.sol";
import { ImmutableGovernanceInformation } from "../proposal/ImmutableGovernanceInformation.sol";

contract TornadoAuctionHandler is ImmutableGovernanceInformation {
  address public constant EasyAuctionAddress = address(0x0b7fFc1f4AD541A4Ed16b40D8c37f0929158D101);
  address public constant WETHAddress = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  uint256 public auctionCounter;

  event TornadoAuctionHandlerCreated(address indexed _handler);

  constructor() public {
    emit TornadoAuctionHandlerCreated(address(this));
  }

  modifier onlyGovernance() {
    require(msg.sender == GovernanceAddress, "only gov");
    _;
  }

  function initializeAuction(
    uint256 _auctionEndDate,
    uint96 _auctionedSellAmount,
    uint96 _minBuyAmount,
    uint256 _minBidPerOrder,
    uint256 _minFundingThreshold
  ) external onlyGovernance {
    require(IERC20(TornTokenAddress).balanceOf(address(this)) >= _auctionedSellAmount, "torn balance not enough");
    IERC20(TornTokenAddress).approve(EasyAuctionAddress, _auctionedSellAmount);

    auctionCounter = IEasyAuction(EasyAuctionAddress).initiateAuction(
      IERC20(TornTokenAddress),
      IERC20(WETHAddress),
      0,
      _auctionEndDate,
      _auctionedSellAmount,
      _minBuyAmount,
      _minBidPerOrder,
      _minFundingThreshold,
      true,
      address(0x0000000000000000000000000000000000000000),
      new bytes(0)
    );
  }

  function convertAndTransferToGovernance() external {
    IWETH(WETHAddress).withdraw(IWETH(WETHAddress).balanceOf(address(this)));
    require(address(this).balance >= 0 ether, "something went wrong");
    IGovernanceDepositInterface(GovernanceAddress).depositEthereumForGasCompensations.value(address(this).balance)();
  }

  receive() external payable {}

  function getAuctionCounter() external view returns (uint256) {
    return auctionCounter;
  }
}
