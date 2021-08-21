// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BASEFEE_PROXY} from "./BASEFEE_PROXY.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import "hardhat/console.sol";

contract GasCalculator is BASEFEE_PROXY {
    using SafeMath for uint256;

    constructor(address _logic) public BASEFEE_PROXY(_logic) {}

    function _calcApproxEthUsedForTxNoPriorityFee(
        address target,
        bytes memory payload
    ) internal returns (uint256) {
        uint256 startGas = gasleft();
	console.log("Here! %s", target);
        (bool success, ) = target.call(payload);
	console.log("Here!");
        require(success, "Call did not succeed");
        uint256 gasDiff = startGas.sub(gasleft());
        gasDiff += 21000;
        return gasDiff.mul(RETURN_BASEFEE());
    }
}
