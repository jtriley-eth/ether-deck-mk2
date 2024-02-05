// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

/// @title Ether Deck Mk2 Flatline Mod
/// @author jtriley.eth
/// @notice a reasonably optimized "dead man switch" mod for Ether Deck Mk2
contract FlatlineMod {
    mapping(bytes4 => address) internal dispatch;
    address internal runner;

    /// @notice sets contingency
    /// @dev directives:
    ///      01. check if caller is runner; revert if not
    ///      02. bitpack receiver, interval, and current timestamp into value
    ///      03. store value in flatline slot
    /// @dev flatline slot is defined as `keccak256("EtherDeckMk2.FlatlineSlot") - 1`
    /// @dev flatline value is defined as `receiver_u160 . interval_u32 . lastUpdate_u64`
    /// @dev setting the interval to zero will disable the contingency
    /// @param receiver the address to receive the contingency
    /// @param interval the interval in seconds for the contingency
    function setContingency(address receiver, uint32 interval) external {
        assembly {
            if iszero(eq(caller(), sload(runner.slot))) { revert(0x00, 0x00) }

            let value := or(timestamp(), or(shl(0x40, interval), shl(0x60, receiver)))

            sstore(0x2baf74cad7040289b2b1fedcfd3140834838fbbf2e2d05fd8eb72bdb1660b9d0, value)
        }
    }

    /// @notice checks in, sets lastUpdate to current timestamp
    /// @dev directives:
    ///      01. check if caller is runner; revert if not
    ///      02. load value from flatline slot; cache as value
    ///      03. mask lastUpdate from value, set to current timestamp; cache as value
    ///      04. store value in flatline slot
    /// @dev flatline slot is defined as `keccak256("EtherDeckMk2.FlatlineSlot") - 1`
    /// @dev flatline value is defined as `receiver_u160 . interval_u32 . lastUpdate_u64`
    function checkIn() external {
        assembly {
            if iszero(eq(caller(), sload(runner.slot))) { revert(0x00, 0x00) }

            let value := sload(0x2baf74cad7040289b2b1fedcfd3140834838fbbf2e2d05fd8eb72bdb1660b9d0)

            value := or(and(value, not(0xffffffffffffffff)), timestamp())

            sstore(0x2baf74cad7040289b2b1fedcfd3140834838fbbf2e2d05fd8eb72bdb1660b9d0, value)
        }
    }

    /// @notice executes contingency
    /// @dev directives:
    ///      01. load value from flatline slot; cache as value
    ///      02. mask last update from value; cache as lastUpdate
    ///      03. mask interval from value; cache as interval
    ///      04. check if an interval has passed since last update and that interval is nonzero; revert if not
    ///      05. store receiver to runner slot
    ///      05. clear flatline slot
    /// @dev flatline slot is defined as `keccak256("EtherDeckMk2.FlatlineSlot") - 1`
    /// @dev flatline value is defined as `receiver_u160 . interval_u32 . lastUpdate_u64`
    function contingency() external {
        assembly {
            let value := sload(0x2baf74cad7040289b2b1fedcfd3140834838fbbf2e2d05fd8eb72bdb1660b9d0)

            let lastUpdate := and(value, 0xffffffffffffffff)

            let interval := and(shr(0x40, value), 0xffffffff)

            if or(lt(timestamp(), add(lastUpdate, interval)), iszero(interval)) { revert(0x00, 0x00) }

            sstore(runner.slot, shr(0x60, value))

            sstore(0x2baf74cad7040289b2b1fedcfd3140834838fbbf2e2d05fd8eb72bdb1660b9d0, 0x00)
        }
    }
}
