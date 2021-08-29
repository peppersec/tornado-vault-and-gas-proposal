// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {Governance} from "../virtualGovernance/Governance.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LoopbackProxy} from "../../tornado-governance/contracts/LoopbackProxy.sol";

library ProposalLibrary {
    function upgradeGovernanceLogicAndReturnAddress(
        Governance _logicAddress,
        address _governance
    ) public returns (address payable) {
        LoopbackProxy(payable(_governance)).upgradeTo(address(_logicAddress));
        return payable(_governance);
    }

    function runCodesAndRevertOnFail(
        Governance _governance,
        bytes[] memory codes
    ) public {
        bool totalSuccess = true;
        for (uint256 i = 0; i < codes.length; i++) {
            (bool singleSuccess, ) = address(_governance).call(codes[i]);
            totalSuccess = (totalSuccess && singleSuccess);
        }
        require(totalSuccess, "some gov fn failed");
    }

    function compareValuesWithCodesAndRevertOnFail(
        Governance _governance,
        bytes[] memory codes,
        bytes32[] memory values
    ) public {
        bool totalSuccess = true;
        for (uint256 i = 0; i < codes.length; i++) {
            (, bytes memory result) = address(_governance).call(codes[i]);
            totalSuccess = (totalSuccess && (values[i] == keccak256(result)));
        }
        require(totalSuccess, "some gov check failed");
    }
}
