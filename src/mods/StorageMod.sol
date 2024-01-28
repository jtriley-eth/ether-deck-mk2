// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

/// @title Ether Deck Mk2 Storage Mod
/// @author jtriley.eth
/// @notice a reasonably optimized batch storage writer for Ether Deck Mk2
contract StorageMod {
    mapping(bytes4 => address) internal dispatch;
    address internal runner;
    uint256 internal nonce;

    /// @notice writes storage in batch
    /// @dev Directives:
    ///      01. if caller is not runner, revert
    ///      02. load slot offset; cache as slotOffset
    ///      03. load value offset; cache as valueOffset
    ///      04. loop:
    ///          a. load slot from calldata
    ///          b. if slot is zero, break loop
    ///          c. store value to slot
    ///          d. increment slot offset
    ///          e. increment value offset
    /// @param slots the slots to write
    /// @param values the values to write
    function write(bytes32[] calldata slots, bytes32[] calldata values) external {
        assembly {
            if iszero(and(eq(caller(), sload(runner.slot)), eq(slots.length, values.length))) { revert(0x00, 0x00) }

            let slotOffset := slots.offset

            let valueOffset := values.offset

            for { } 1 { } {
                let slot := calldataload(slotOffset)

                if iszero(slot) { break }

                sstore(slot, calldataload(valueOffset))

                slotOffset := add(slotOffset, 0x20)

                valueOffset := add(valueOffset, 0x20)
            }
        }
    }

    /// @notice reads storage in batch
    /// @dev Directives:
    ///      01. load key offset; cache as keyOffset
    ///      02. load array offset; cache as arrayOffset
    ///      03. store slots length in memory
    ///      04. loop:
    ///          a. load key from calldata
    ///          b. if key is zero, break loop
    ///          c. load value from storage; store in memory
    ///          d. increment key offset
    ///          e. increment array offset
    ///      05. return array
    /// @param slots the slots to read
    /// @return array the values read
    function read(bytes32[] calldata slots) external view returns (bytes32[] memory) {
        assembly {
            let keyOffset := slots.offset

            let arrayOffset := 0x20

            mstore(0x00, slots.length)

            for { } 1 { } {
                let key := calldataload(keyOffset)

                if iszero(key) { break }

                mstore(arrayOffset, sload(key))

                keyOffset := add(keyOffset, 0x20)

                arrayOffset := add(arrayOffset, 0x20)
            }

            return(0x00, add(0x20, shr(0x05, slots.length)))
        }
    }
}
