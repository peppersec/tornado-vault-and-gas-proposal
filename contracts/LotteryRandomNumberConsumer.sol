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
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952,
            0x514910771AF9Ca656af840dff83E8264EcF986CA
        )
    {
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        fee = 2 * (10**18); // have to check on reducing gas fee but probably we will find a way to do a single request for the lottery payout
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

    // has to be modified for tornado governance
    function expand(uint256 entropy, uint256 upperBound)
        internal
        pure
        returns (uint256)
    {
        return (uint256(keccak256(abi.encode(randomResult, entropy))) %
            upperBound);
    }
}
