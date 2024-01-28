// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

contract DifferentialModRegistry {
    address public authority;
    mapping(string => address) public searchByName;
    mapping(address => string) public searchByAddress;

    event AuthorityTransferred(address indexed newAuthority);
    event ModRegistered(address indexed addr, string name);

    constructor(address initialAuthority) {
        authority = initialAuthority;
    }

    function transferAuthority(address newAuthority) external {
        require(msg.sender == authority);
        emit AuthorityTransferred(authority = newAuthority);
    }

    function register(address addr, string calldata name) external {
        require(msg.sender == authority && bytes(name).length < 32);
        emit ModRegistered(searchByName[name] = addr, searchByAddress[addr] = name);
    }
}
