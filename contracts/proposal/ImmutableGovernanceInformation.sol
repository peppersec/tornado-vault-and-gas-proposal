// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

contract ImmutableGovernanceInformation {
    address public constant TornadoMultisig =
        address(0xb04E030140b30C27bcdfaafFFA98C57d80eDa7B4);
    address public constant GovernanceAddress =
        address(0x5efda50f22d34F262c29268506C5Fa42cB56A1Ce);
    address public constant TornTokenAddress =
        address(0x77777FeDdddFfC19Ff86DB637967013e6C6A116C);

    function returnPayableGovernance() public returns (address payable) {
        return payable(GovernanceAddress);
    }
}
