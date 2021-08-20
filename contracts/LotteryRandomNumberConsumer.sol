// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

abstract contract LotteryRandomNumberConsumer is VRFConsumerBase {
    bytes32 internal keyHash;
    uint256 internal fee;
    mapping(uint256 => uint256) internal randomResults;
    uint256 internal idForLatestRandomNumber;

    constructor()
        public
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B,
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709
        )
    {
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 1 * (10**17); // have to check on reducing gas fee but probably we will find a way to do a single request for the lottery payout
    }

    /**
     * Requests randomness
     */
    function getRandomNumber() internal returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract"
        );
        return requestRandomness(keyHash, fee);
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
