// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import {LotteryRandomNumberConsumer} from "../LotteryRandomNumberConsumer.sol";

contract LRNCTestImplementation is LotteryRandomNumberConsumer {
    constructor() public LotteryRandomNumberConsumer() {}

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
