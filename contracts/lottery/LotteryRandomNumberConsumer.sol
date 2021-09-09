// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

abstract contract LotteryRandomNumberConsumer is VRFConsumerBase {
  mapping(uint256 => uint256) public randomNumbers;
  uint256 public idForLatestRandomNumber;
  bytes32 public keyHash;

  constructor(
    address _vrfCoordinator,
    address _link,
    bytes32 _keyHash
  ) public VRFConsumerBase(_vrfCoordinator, _link) {
    keyHash = _keyHash;
  }

  /**
   * Requests randomness
   */
  function getRandomNumber(uint256 _fee) internal returns (bytes32) {
    require(LINK.balanceOf(address(this)) >= _fee, "Not enough LINK - fill contract");
    requestRandomness(keyHash, _fee);
  }

  /**
   * Callback function used by VRF Coordinator
   */
  function fulfillRandomness(bytes32, uint256 randomness) internal virtual override;

  function expand(
    uint256 seed,
    uint256 index,
    uint256 upperBound
  ) public pure returns (uint256) {
    return (uint256(keccak256(abi.encode(seed, index))) % upperBound);
  }
}
