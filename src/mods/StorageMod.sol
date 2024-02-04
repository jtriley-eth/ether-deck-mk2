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
    /// @dev directives:
    ///      01. check if caller is runner and slots and values are equal length, revert if not
    ///      02. load slot offset; cache as slotOffset
    ///      03. load value offset; cache as valueOffset
    ///      04. compute end of slots; cache as slotsEnd
    ///      05. loop:
    ///          a. if slotOffset is slotsEnd, break loop
    ///          b. store value to slot
    ///          c. increment slot offset
    ///          d. increment value offset
    /// @param slots the slots to write
    /// @param values the values to write
    function write(bytes32[] calldata slots, bytes32[] calldata values) external {
        assembly {
            if iszero(and(eq(caller(), sload(runner.slot)), eq(slots.length, values.length))) { revert(0x00, 0x00) }

            let slotOffset := slots.offset

            let valueOffset := values.offset

            let slotsEnd := add(slotOffset, mul(slots.length, 0x20))

            for { } 1 { } {
                if eq(slotOffset, slotsEnd) { break }

                sstore(calldataload(slotOffset), calldataload(valueOffset))

                slotOffset := add(slotOffset, 0x20)

                valueOffset := add(valueOffset, 0x20)
            }
        }
    }

    /// @notice reads storage in batch
    /// @dev directives:
    ///      01. load slot offset; cache as slotOffset
    ///      02. load array offset; cache as arrayOffset
    ///      03. compute end of slots; cache as slotsEnd
    ///      04. store slots length in memory
    ///      05. loop:
    ///          a. if slotOffset is slotsEnd, break loop
    ///          b. move value from storage to memory
    ///          c. increment key offset
    ///          d. increment array offset
    ///      06. return array
    /// @param slots the slots to read
    /// @return array the values read
    function read(bytes32[] calldata slots) external view returns (bytes32[] memory) {
        assembly {
            let slotOffset := slots.offset

            let arrayOffset := 0x40

            let slotsEnd := add(slotOffset, mul(slots.length, 0x20))

            mstore(0x00, 0x20)

            mstore(0x20, slots.length)

            for { } 1 { } {
                if eq(slotOffset, slotsEnd) { break }

                mstore(arrayOffset, sload(calldataload(slotOffset)))

                slotOffset := add(slotOffset, 0x20)

                arrayOffset := add(arrayOffset, 0x20)
            }

            return(0x00, add(0x40, mul(slots.length, 0x20)))
        }
    }
}
