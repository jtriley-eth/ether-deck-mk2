// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

/// @title Ether Deck Mk2 Creator Mod
/// @author jtriley.eth
/// @notice a reasonably optimized contract creator mod for Ether Deck Mk2
contract CreatorMod {
    mapping(bytes4 => address) internal dispatch;
    address internal runner;

    /// @notice creates a contract with value and initcode
    /// @dev directives:
    ///      01. check if caller is runner; cache as succes
    ///      02. copy initcode to memory
    ///      03. create contract; cache as deployment
    ///      04. check if deployment is nonzero; compose success
    ///      05. store deployment in memory
    ///      06. if success, return deployment
    ///      07. else, revert
    /// @dev usees `create` opcode
    /// @param value value of creation
    /// @param initcode initialization code
    /// @return deployment the address of the deployment
    function create(uint256 value, bytes calldata initcode) external payable returns (address) {
        assembly {
            let success := eq(caller(), sload(runner.slot))

            calldatacopy(0x00, initcode.offset, initcode.length)

            let deployment := create(value, 0x00, initcode.length)

            success := and(success, iszero(iszero(deployment)))

            mstore(0x00, deployment)

            if success { return(0x00, 0x20) }

            revert(0x00, 0x00)
        }
    }

    /// @notice creates a contract with salt, value, and initcode
    /// @dev directives:
    ///      01. check if caller is runner; cache as success
    ///      02. copy initcode to memory
    ///      03. create contract; cache as deployment
    ///      04. check if deployment is nonzero; compose success
    ///      05. store deployment in memory
    ///      06. if success, return deployment
    ///      07. else, revert
    /// @dev uses `create2` opcode
    /// @param salt salt of creation
    /// @param value value of creation
    /// @param initcode initialization code
    /// @return deployment the address of the deployment
    function create2(bytes32 salt, uint256 value, bytes calldata initcode) external payable returns (address) {
        assembly {
            let success := eq(caller(), sload(runner.slot))

            calldatacopy(0x00, initcode.offset, initcode.length)

            let deployment := create2(value, 0x00, initcode.length, salt)

            success := and(success, iszero(iszero(deployment)))

            mstore(0x00, deployment)

            if success { return(0x00, 0x20) }

            revert(0x00, 0x00)
        }
    }

    /// @notice computes the address of a contract with salt and initcode
    /// @dev directives:
    ///      01. copy initcode in memory
    ///      02. hash initcode, store in memory
    ///      03. store salt in memory
    ///      04. compose `0xff` and caller, store in memory
    ///      05. hash create2 address computation parameters, mask as address; cache as deployment
    ///      06. store deployment in memory
    ///      07. return deployment
    /// @dev create2 address computation parameters is defined as `ff . caller_u160 . salt_u160 . keccak256(initcode)`
    /// @param salt creation salt
    /// @param initcode initialization code
    /// @return deployment the address of the deployment
    function compute2(bytes32 salt, bytes calldata initcode) external view returns (address) {
        assembly {
            calldatacopy(0x00, initcode.offset, initcode.length)

            mstore(0x40, keccak256(0x00, initcode.length))

            mstore(0x20, salt)

            mstore(0x00, or(address(), 0xff0000000000000000000000000000000000000000))

            let deployment := and(keccak256(0x0b, 0x55), 0xffffffffffffffffffffffffffffffffffffffff)

            mstore(0x00, deployment)

            return(0x00, 0x20)
        }
    }
}
