// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import {LotteryRandomNumberConsumer} from "../LotteryRandomNumberConsumer.sol";

contract LRNCTestImplementation is LotteryRandomNumberConsumer {
    mapping(uint256 => uint256) randomResults;

    constructor()
        public
        LotteryRandomNumberConsumer(
            address(0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B),
            address(0x01BE23585060835E02B77ef475b0Cc51aA1e0709),
            bytes32(
                0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311
            ),
            (10**17)
        )
    {}

    function callGetRandomNumber() external {
        getRandomNumber();
    }

    function getRandomResult(uint256 id) external view returns (uint256) {
        return randomResults[id];
    }

    function setIdForLatestRandomNumber(uint256 _idForLatestRandomNumber)
        external
    {
        idForLatestRandomNumber = _idForLatestRandomNumber;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        randomResults[idForLatestRandomNumber] = randomness;
    }

    function expandPublic(
        uint256 resultId,
        uint256 entropy,
        uint256 upperBound
    ) internal view returns (uint256) {
        return expand(resultId, entropy, upperBound);
    }
}
