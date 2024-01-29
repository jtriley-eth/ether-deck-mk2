// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

contract CreatorMod {
    mapping(bytes4 => address) internal dispatch;
    address internal runner;
    uint256 internal nonce;

    function create(bytes calldata initcode) external returns (address) {
        assembly {
            let success := eq(caller(), sload(runner.slot))

            let deployment := create(0x00, initcode.offset, initcode.length)

            success := and(success, iszero(iszero(deployment)))

            mstore(0x00, deployment)

            if success { return(0x00, 0x20) }

            revert(0x00, 0x00)
        }
    }

    function create2(bytes32 salt, bytes calldata initcode) external returns (address) {
        assembly {
            let success := eq(caller(), sload(runner.slot))

            let deployment := create2(0x00, initcode.offset, initcode.length, salt)

            success := and(success, iszero(iszero(deployment)))

            mstore(0x00, deployment)

            if success { return(0x00, 0x20) }

            revert(0x00, 0x00)
        }
    }

    function compute2(bytes32 salt, bytes calldata initcode) external view returns (address) {
        assembly {
            calldatacopy(0x00, initcode.offset, initcode.length)

            mstore(0x40, keccak256(0x00, initcode.length))

            mstore(0x20, salt)

            mstore(0x00, or(caller(), 0xff0000000000000000000000000000000000000000))

            mstore(0x00, keccak256(0x0b, 0x51))

            return(0x00, 0x20)
        }
    }
}
