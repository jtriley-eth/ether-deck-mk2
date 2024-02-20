// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

import { DeckHub } from "../src/DeckHub.sol";
import { EtherDeckMk2 } from "../src/EtherDeckMk2.sol";

import { Test } from "../lib/forge-std/src/Test.sol";

contract DeckHubTest is Test {
    DeckHub internal hub;

    address alice = vm.addr(1);
    bytes32 defaultSalt = bytes32(uint256(0x01));

    function setUp() public {
        hub = new DeckHub();
    }

    function testDeploy() public {
        vm.expectEmit(true, true, true, true);
        emit DeckHub.Deployed(alice, compute(alice, defaultSalt));

        vm.prank(alice);
        EtherDeckMk2 deck = EtherDeckMk2(payable(hub.deploy(alice, defaultSalt)));

        assertEq(deck.runner(), alice);
    }

    function testFuzzDeploy(address actor, address runner, bytes32 salt) public {
        vm.expectEmit(true, true, true, true);
        emit DeckHub.Deployed(actor, compute(runner, salt));

        vm.prank(actor);
        EtherDeckMk2 deck = EtherDeckMk2(payable(hub.deploy(runner, salt)));

        assertEq(deck.runner(), runner);
    }

    function compute(address runner, bytes32 salt) internal view returns (address) {
        return address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(hub),
                            salt,
                            keccak256(abi.encodePacked(type(EtherDeckMk2).creationCode, uint256(uint160(runner))))
                        )
                    )
                )
            )
        );
    }
}
