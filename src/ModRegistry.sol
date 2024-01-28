// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

/// @title Ether Deck Mk2 Mod Registry
/// @author jtriley.eth
/// @notice Registers mods for the Ether Deck Mk2 with bidirectional lookup
contract ModRegistry {
    address public authority;
    mapping(string => address) public searchByName;
    mapping(address => string) public searchByAddress;

    event AuthorityTransferred(address indexed newAuthority);
    event ModRegistered(address indexed addr, string name);

    constructor(address initialAuthority) {
        assembly {
            sstore(authority.slot, initialAuthority)
        }
    }

    function transferAuthority(address newAuthority) external {
        assembly {
            if iszero(eq(caller(), sload(authority.slot))) { revert(0x00, 0x00) }

            sstore(authority.slot, newAuthority)

            log2(0x00, 0x00, 0x5b0c3a2a09ee4c3913f0ea177afea723d04e080d3fff121bf6dab07c9bc1ca3d, newAuthority)
        }
    }

    function register(address addr, string calldata name) external {
        assembly {
            if iszero(and(eq(caller(), sload(authority.slot)), lt(name.length, 0x20))) { revert(0x00, 0x00) }

            mstore(0x00, addr)

            mstore(0x20, searchByAddress.slot)

            sstore(keccak256(0x00, 0x40), or(calldataload(name.offset), mul(name.length, 0x02)))

            mstore(0x00, 0x20)

            mstore(0x20, name.length)

            mstore(0x40, calldataload(name.offset))

            mstore(add(name.length, 0x40), searchByName.slot)

            sstore(keccak256(0x40, add(name.length, 0x20)), addr)

            mstore(0x40, calldataload(name.offset))

            let len := add(0x40, mul(iszero(iszero(name.length)), 0x20))

            log2(0x00, len, 0x53847476bca505044595421c78566864f28f19c3f4597502069d145bbe5a62b7, addr)
        }
    }
}
