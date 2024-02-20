// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

import { EtherDeckMk2 } from "../../../src/EtherDeckMk2.sol";

contract DifferentialDeckHub {
    event Deployed(address indexed deployer, address indexed deck);

    function deploy(address runner, bytes32 salt) external returns (address deck) {
        deck = address(new EtherDeckMk2{ salt: salt }(runner));

        emit Deployed(msg.sender, deck);
    }
}
