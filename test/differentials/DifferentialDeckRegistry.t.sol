// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

import { DeckRegistry } from "../../src/DeckRegistry.sol";
import { DifferentialDeckRegistry } from "./implementations/DifferentialDeckRegistry.sol";

import { EtherDeckMk2 } from "../../src/EtherDeckMk2.sol";

import { Test } from "../../lib/forge-std/src/Test.sol";

contract DifferentialDeckRegistryTest is Test {
    DeckRegistry internal fastRegistry;
    DifferentialDeckRegistry internal slowRegistry;

    function setUp() public {
        address initialDeck = vm.addr(1);

        fastRegistry = new DeckRegistry(initialDeck);
        slowRegistry = new DifferentialDeckRegistry(initialDeck);
    }

    function testFuzzDiffDeploy(bool actorIsInitial, address actor, address initial, address runner) public {
        actor = actorIsInitial ? initial : actor;

        fastRegistry = new DeckRegistry(initial);
        slowRegistry = new DifferentialDeckRegistry(initial);

        vm.startPrank(actor);
        if (actor == initial) {
            address fastDeck = fastRegistry.deploy(runner);
            address slowDeck = slowRegistry.deploy(runner);

            assertEq(fastRegistry.deployer(fastDeck), initial);
            assertEq(slowRegistry.deployer(slowDeck), initial);
            assertEq(EtherDeckMk2(payable(fastDeck)).runner(), runner);
            assertEq(EtherDeckMk2(payable(slowDeck)).runner(), runner);
        } else {
            vm.expectRevert();
            fastRegistry.deploy(runner);

            vm.expectRevert();
            slowRegistry.deploy(runner);
        }
        vm.stopPrank();
    }

    function testFuzzDiffChainDeploy(address initial, address runner, address secondary) public {
        initial = initial == address(0) ? address(1) : initial;

        fastRegistry = new DeckRegistry(initial);
        slowRegistry = new DifferentialDeckRegistry(initial);

        vm.startPrank(initial);
        EtherDeckMk2 fastDeck = EtherDeckMk2(payable(fastRegistry.deploy(runner)));
        EtherDeckMk2 slowDeck = EtherDeckMk2(payable(slowRegistry.deploy(runner)));
        vm.stopPrank();

        vm.startPrank(runner);
        fastDeck.run(address(fastRegistry), abi.encodeWithSelector(DeckRegistry.deploy.selector, secondary));
        address fastChainDeck;
        assembly {
            returndatacopy(0x00, 0x00, 0x20)
            fastChainDeck := mload(0x00)
        }

        slowDeck.run(address(slowRegistry), abi.encodeWithSelector(DifferentialDeckRegistry.deploy.selector, secondary));

        address slowChainDeck;
        assembly {
            returndatacopy(0x00, 0x00, 0x20)
            slowChainDeck := mload(0x00)
        }
        vm.stopPrank();

        assertEq(fastRegistry.deployer(address(fastDeck)), initial);
        assertEq(slowRegistry.deployer(address(slowDeck)), initial);
        assertEq(fastDeck.runner(), runner);
        assertEq(slowDeck.runner(), runner);
        assertEq(fastRegistry.deployer(fastChainDeck), address(fastDeck));
        assertEq(slowRegistry.deployer(slowChainDeck), address(slowDeck));
        assertEq(EtherDeckMk2(payable(fastChainDeck)).runner(), secondary);
        assertEq(EtherDeckMk2(payable(slowChainDeck)).runner(), secondary);
    }
}
