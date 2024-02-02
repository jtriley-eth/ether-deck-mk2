// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

contract MockTarget {
    bool internal throws;

    constructor() payable {}

    function setThrows(bool _throws) public {
        throws = _throws;
    }

    fallback() external payable {
        assembly {
            calldatacopy(0x00, 0x00, calldatasize())
            if sload(throws.slot) { revert(0x00, calldatasize()) }
            return(0x00, calldatasize())
        }
    }

    receive() external payable {
        assembly {
            if sload(throws.slot) { revert(0x00, calldatasize()) }
        }
    }
}
