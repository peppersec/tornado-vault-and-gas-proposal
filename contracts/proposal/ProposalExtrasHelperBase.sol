// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {ImmutableGovernanceInformation} from "./ImmutableGovernanceInformation.sol";

abstract contract ProposalExtrasHelperBase is ImmutableGovernanceInformation {
    function nestedFunctionsGovernance() external virtual;

    function runCodesAndRevertOnFail(bytes[] memory codes) public {
        bool totalSuccess = true;
        for (uint256 i = 0; i < codes.length; i++) {
            (bool singleSuccess, ) = GovernanceAddress.call(codes[i]);
            totalSuccess = (totalSuccess && singleSuccess);
        }
        require(totalSuccess, "some gov fn failed");
    }

    function compareValuesWithCodesAndRevertOnFail(
        bytes[] memory codes,
        bytes32[] memory values
    ) public {
        bool totalSuccess = true;
        for (uint256 i = 0; i < codes.length; i++) {
            (, bytes memory result) = GovernanceAddress.call(codes[i]);
            totalSuccess = (totalSuccess && (values[i] == keccak256(result)));
        }
        require(totalSuccess, "some gov check failed");
    }
}
