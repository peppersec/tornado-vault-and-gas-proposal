// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BASEFEE_PROXY} from "./BASEFEE_PROXY.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

abstract contract GasCalculator is BASEFEE_PROXY {
    using SafeMath for uint256;

    bool public gasCompensationsPaused;
    uint256 public gasCompensationsLimit;

    constructor(address _logic) public BASEFEE_PROXY(_logic) {}

    modifier gasCompensation(address account, bool eligible, uint256 extra) {
        if (!gasCompensationsPaused && eligible) {
            uint256 startGas = gasleft();
            _;
            uint256 gasDiff = startGas.sub(gasleft());
            uint256 toCompensate = gasDiff.mul(RETURN_BASEFEE());
	    toCompensate += extra;

            toCompensate = (toCompensate < gasCompensationsLimit)
                ? toCompensate
                : gasCompensationsLimit;

	    require(payable(account).send(toCompensate), "gas compensation failed");
         
            gasCompensationsLimit -= toCompensate;
        } else {
            _;
        }
    }

    function setGasCompensationsLimit(uint256 _gasCompensationsLimit)
        external
        virtual;

    function pauseOrUnpauseGasCompensations() external virtual;
}
