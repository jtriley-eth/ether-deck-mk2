// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

import { EtherDeckMk2 } from "../../../src/EtherDeckMk2.sol";

contract DifferentialDeckRegistry {
    event Registered(address indexed deployer, address indexed deck);

    mapping(address => address) public deployer;

    constructor(address initialDeck) {
        deployer[initialDeck] = initialDeck;
    }

    function deploy(address runner) external returns (address) {
        require(deployer[msg.sender] != address(0));
        address deck = address(new EtherDeckMk2(runner));
        deployer[deck] = msg.sender;
        emit Registered(msg.sender, deck);
        return deck;
    }
}
