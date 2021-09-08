// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface ITornadoLottery {
  function registerLotteryAccount(
    uint256 proposalId,
    address account,
    uint96 accountVotes
  ) external;
}
