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
            if iszero(and(eq(sload(runner.slot), caller()), eq(slots.length, values.length))) { revert(0x00, 0x00) }

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
}
