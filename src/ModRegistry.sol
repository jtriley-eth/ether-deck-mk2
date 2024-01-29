// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

/// @title Ether Deck Mk2 Mod Registry
/// @author jtriley.eth
/// @notice registers mods for the Ether Deck Mk2 with bidirectional lookup
contract ModRegistry {
    address public authority;
    mapping(string => address) public searchByName;
    mapping(address => string) public searchByAddress;

    /// @notice logged on authority transfer
    /// @param newAuthority the new authority
    event AuthorityTransferred(address indexed newAuthority);

    /// @notice logged on mod registration
    /// @param addr the mod address
    /// @param name the mod name
    event ModRegistered(address indexed addr, string name);

    constructor(address initialAuthority) {
        assembly {
            sstore(authority.slot, initialAuthority)
        }
    }

    /// @notice transfers authority
    /// @dev directives:
    ///      01. check if caller is authority; revert if not
    ///      02. store new authority in storage
    ///      03. log authority transfer
    /// @param newAuthority the new authority
    function transferAuthority(address newAuthority) external {
        assembly {
            if iszero(eq(caller(), sload(authority.slot))) { revert(0x00, 0x00) }

            sstore(authority.slot, newAuthority)

            log2(0x00, 0x00, 0x5b0c3a2a09ee4c3913f0ea177afea723d04e080d3fff121bf6dab07c9bc1ca3d, newAuthority)
        }
    }

    /// @notice registers a mod
    /// @dev directives:
    ///      01. check if caller is authority and name length is less than 32; revert if not
    ///      02. store address in memory
    ///      03. store searchByAddress index in memory
    ///      04. compute searchByAddress slot, store name in storage
    ///      05. store name offset in memory
    ///      06. store name length in memory
    ///      07. store name in memory
    ///      08. store searchByName index in memory
    ///      09. compute searchByName slot, store address in storage
    ///      10. compute name length for event; cache as len
    ///      11. log mod registration
    /// @dev we branchlessly compute `len` to be `0x40` if `name` is empty, else `0x60`
    /// @param modAddress the mod address
    /// @param modName the mod name
    function register(address modAddress, string calldata modName) external {
        assembly {
            if iszero(and(eq(caller(), sload(authority.slot)), lt(modName.length, 0x20))) { revert(0x00, 0x00) }

            mstore(0x00, modAddress)

            mstore(0x20, searchByAddress.slot)

            sstore(keccak256(0x00, 0x40), or(calldataload(modName.offset), mul(modName.length, 0x02)))

            mstore(0x00, 0x20)

            mstore(0x20, modName.length)

            mstore(0x40, calldataload(modName.offset))

            mstore(add(modName.length, 0x40), searchByName.slot)

            sstore(keccak256(0x40, add(modName.length, 0x20)), modAddress)

            mstore(0x40, calldataload(modName.offset))

            let len := add(0x40, mul(iszero(iszero(modName.length)), 0x20))

            log2(0x00, len, 0x53847476bca505044595421c78566864f28f19c3f4597502069d145bbe5a62b7, modAddress)
        }
    }
}
