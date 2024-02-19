// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

import { DeckRegistry } from "../src/DeckRegistry.sol";
import { EtherDeckMk2 } from "../src/EtherDeckMk2.sol";

import { Test } from "../lib/forge-std/src/Test.sol";

contract DeckRegistryTest is Test {
    DeckRegistry internal registry;

    address initialDeck = vm.addr(1);
    address defaultRunner = vm.addr(2);
    address secondaryRunner = vm.addr(3);

    function setUp() public {
        registry = new DeckRegistry(initialDeck);
    }

    function testInitial() public {
        assertEq(registry.deployer(initialDeck), initialDeck);
    }

    function testDeploy() public {
        vm.prank(initialDeck);

        address deck = registry.deploy(defaultRunner);

        assertEq(registry.deployer(deck), initialDeck);
        assertEq(EtherDeckMk2(payable(deck)).runner(), defaultRunner);
    }

    function testDeployFail() public {
        vm.expectRevert();

        vm.prank(defaultRunner);

        registry.deploy(defaultRunner);
    }

    function testChainDeploy() public {
        vm.prank(initialDeck);

        EtherDeckMk2 deck = EtherDeckMk2(payable(registry.deploy(defaultRunner)));

        vm.prank(defaultRunner);
        deck.run(address(registry), abi.encodeCall(DeckRegistry.deploy, (secondaryRunner)));

        address chainDeck;
        assembly {
            returndatacopy(0x00, 0x00, 0x20)
            chainDeck := mload(0x00)
        }

        assertEq(registry.deployer(address(deck)), initialDeck);
        assertEq(deck.runner(), defaultRunner);
        assertEq(registry.deployer(chainDeck), address(deck));
        assertEq(EtherDeckMk2(payable(chainDeck)).runner(), secondaryRunner);
    }

    function testFuzzDeploy(bool actorIsInitial, address actor, address initial, address runner) public {
        actor = actorIsInitial ? initial : actor;

        registry = new DeckRegistry(initial);

        if (actor == initial) {
            vm.prank(actor);
            address deck = registry.deploy(runner);

            assertEq(registry.deployer(deck), initial);
            assertEq(EtherDeckMk2(payable(deck)).runner(), runner);
        } else {
            vm.expectRevert();
            vm.prank(actor);
            registry.deploy(runner);
        }
    }

    function testFuzzDeployChain(
        address initial,
        address runner,
        address secondary
    ) public {
        initial = initial == address(0) ? address(1) : initial;

        registry = new DeckRegistry(initial);

        vm.prank(initial);
        EtherDeckMk2 deck = EtherDeckMk2(payable(registry.deploy(runner)));

        vm.prank(runner);
        deck.run(address(registry), abi.encodeCall(DeckRegistry.deploy, (secondary)));
        address chainDeck;
        assembly {
            returndatacopy(0x00, 0x00, 0x20)
            chainDeck := mload(0x00)
        }

        assertEq(registry.deployer(address(deck)), initial);
        assertEq(deck.runner(), runner);
        assertEq(registry.deployer(chainDeck), address(deck));
        assertEq(EtherDeckMk2(payable(chainDeck)).runner(), secondary);
    }
}
