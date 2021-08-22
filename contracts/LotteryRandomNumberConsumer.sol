// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

abstract contract LotteryRandomNumberConsumer is VRFConsumerBase {
    bytes32 public lastRequestId;

    bytes32 internal keyHash;
    uint256 internal fee;
    mapping(uint256 => uint256) internal randomResults;
    uint256 internal idForLatestRandomNumber;

    constructor(
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _fee
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        keyHash = _keyHash;
        fee = _fee; // have to check on reducing gas fee but probably we will find a way to do a single request for the lottery payout
    }

    /**
     * Requests randomness
     */
    function getRandomNumber() internal returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract"
        );
        lastRequestId = requestRandomness(keyHash, fee);
	return lastRequestId;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        virtual
        override;

    function expand(
        uint256 resultId,
        uint256 entropy,
        uint256 upperBound
    ) internal view returns (uint256) {
        return (uint256(
            keccak256(abi.encode(randomResults[resultId], entropy))
        ) % upperBound);
    }
}
