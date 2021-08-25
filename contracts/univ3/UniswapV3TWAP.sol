// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import "./TickMath.sol";
import "./FullMath.sol";

library UniswapV3TWAP {
    function getTWAPFromPool(address uniswapV3Pool, uint32 twapInterval)
        external
        view
        returns (uint256)
    {
        uint160 sqrtPriceX96;
        if (twapInterval == 0) {
            // return the current price if twapInterval == 0
            (bool success, bytes memory results) = uniswapV3Pool.staticcall(
                abi.encodeWithSignature("slot0()")
            );

            require(success, "uniswapV3Pool::slot0 fail");

            (sqrtPriceX96, , , , , , ) = abi.decode(
                results,
                (uint160, int24, uint16, uint16, uint16, uint8, bool)
            );
        } else {
            uint32[] memory secondsAgos = new uint32[](2);
            secondsAgos[0] = twapInterval; // from (before)
            secondsAgos[1] = 0; // to (now)

            (bool success, bytes memory results) = uniswapV3Pool.staticcall(
                abi.encodeWithSignature("observe(uint32[])", secondsAgos)
            );

            require(success, "uniswapV3Pool::observe fail");

            (int56[] memory tickCumulatives, ) = abi.decode(
                results,
                (int56[], uint160[])
            );

            // tick(imprecise as it's an integer) to price
            sqrtPriceX96 = TickMath.getSqrtRatioAtTick(
                int24((tickCumulatives[1] - tickCumulatives[0]) / twapInterval)
            );
        }

        uint256 sqrtPriceX96256 = uint256(sqrtPriceX96);

        return
            FullMath.mulDiv(sqrtPriceX96256, sqrtPriceX96256, FixedPoint96.Q96);
    }
}
