// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

library LotteryProposalSpecific {
    function enpackSetupCodes(uint256 votingPeriod) public pure returns (bytes[] memory codes) {
        codes = new bytes[](3);
        codes[0] = abi.encodeWithSignature("deployLottery()");
        codes[1] = abi.encodeWithSignature("deployVault()");
        codes[2] = abi.encodeWithSignature(
            "setVotingPeriod(uint256)",
            votingPeriod
        );
    }

    function enpackCheckCodes() public pure returns (bytes[] memory codes) {
        codes = new bytes[](2);
        codes[0] = abi.encodeWithSignature("VOTING_PERIOD()");
        codes[1] = abi.encodeWithSignature("TornadoMultisig()");
    }

    function enpackCheckArgs(uint256 votingPeriod, address TornadoMultisig) public pure returns (bytes32[] memory args) {
        args = new bytes32[](2);
        args[0] = keccak256(abi.encode(votingPeriod));
        args[1] = keccak256(abi.encode(TornadoMultisig));
    }
}