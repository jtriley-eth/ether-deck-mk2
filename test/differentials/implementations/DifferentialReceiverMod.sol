// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

contract DifferentialReceiverMod {
    mapping(bytes4 => address) internal dispatch;
    address internal runner;

    fallback() external payable {
        bytes4 selector = msg.sig;
        assembly {
            mstore(0x00, selector)
            return(0x00, 0x20)
        }
    }

    receive() external payable { }
}
