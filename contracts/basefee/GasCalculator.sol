// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BASEFEE_PROXY} from "./BASEFEE_PROXY.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

abstract contract GasCalculator is BASEFEE_PROXY {
    using SafeMath for uint256;

    bool public gasCompensationsPaused;
    uint256 public gasTokenAmountInEther;

    constructor(address _logic) public BASEFEE_PROXY(_logic) {}

    modifier gasCompensation(address account, bool eligible) {
        if (!gasCompensationsPaused && eligible) {
            uint256 startGas = gasleft();
            _;
            uint256 gasDiff = startGas.sub(gasleft());
            gasDiff += 21000;
            uint256 result = gasDiff.mul(RETURN_BASEFEE());
            _compensateGasLogic(account, result);
        } else {
            _;
        }
    }

    function setSpendableTornForGasCompensations(uint256 _gasTokenAmountInEther)
        external
        virtual;

    function pauseOrUnpauseGasCompensations() external virtual;

    function _compensateGasLogic(address account, uint256 amount)
        internal
        virtual;
}
