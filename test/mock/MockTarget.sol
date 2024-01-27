// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

contract MockTarget {
    fallback() external payable {
        assembly {
            calldatacopy(0x00, 0x00, calldatasize())
            return(0x00, calldatasize())
        }
    }

    receive() external payable {}
}
