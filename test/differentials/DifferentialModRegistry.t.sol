// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import { Test, console } from "../../lib/forge-std/src/Test.sol";

import { ModRegistry } from "../../src/ModRegistry.sol";
import { DifferentialModRegistry } from "./implementations/DifferentialModRegistry.sol";

contract DifferentialModRegistryTest is Test {
    ModRegistry internal fastRegistry;
    DifferentialModRegistry internal slowRegistry;
    address internal initialAuthority = vm.addr(1);

    function setUp() public {
        fastRegistry = new ModRegistry(initialAuthority);
        slowRegistry = new DifferentialModRegistry(initialAuthority);
    }

    function testFuzzDiffTransferAuthority(
        bool actorIsAuthority,
        address actor,
        address authority,
        address secondaryAuthority
    ) public {
        actor = actorIsAuthority ? authority : actor;

        vm.startPrank(initialAuthority);

        fastRegistry.transferAuthority(authority);
        slowRegistry.transferAuthority(authority);

        vm.stopPrank();

        vm.startPrank(actor);

        if (actor == authority) {
            vm.expectEmit(true, true, true, true);
            emit ModRegistry.AuthorityTransferred(secondaryAuthority);
            fastRegistry.transferAuthority(secondaryAuthority);

            vm.expectEmit(true, true, true, true);
            emit ModRegistry.AuthorityTransferred(secondaryAuthority);
            slowRegistry.transferAuthority(secondaryAuthority);

            assertEq(fastRegistry.authority(), secondaryAuthority);
            assertEq(slowRegistry.authority(), secondaryAuthority);
        } else {
            vm.expectRevert();
            fastRegistry.transferAuthority(secondaryAuthority);

            vm.expectRevert();
            slowRegistry.transferAuthority(secondaryAuthority);

            assertEq(fastRegistry.authority(), authority);
            assertEq(slowRegistry.authority(), authority);
        }

        vm.stopPrank();
    }

    function testFuzzDiffRegister(
        bool actorIsAuthority,
        address actor,
        address authority,
        address modAddress,
        string memory modName
    ) public {
        actor = actorIsAuthority ? authority : actor;

        vm.startPrank(initialAuthority);

        fastRegistry.transferAuthority(authority);
        slowRegistry.transferAuthority(authority);

        vm.stopPrank();

        assertEq(fastRegistry.searchByName(modName), address(0x0));
        assertEq(fastRegistry.searchByAddress(modAddress), "");

        assertEq(slowRegistry.searchByName(modName), address(0x0));
        assertEq(slowRegistry.searchByAddress(modAddress), "");

        vm.startPrank(actor);

        if (actor == authority && bytes(modName).length < 32) {
            vm.expectEmit(true, true, true, true);
            emit ModRegistry.ModRegistered(modAddress, modName);
            fastRegistry.register(modAddress, modName);

            vm.expectEmit(true, true, true, true);
            emit ModRegistry.ModRegistered(modAddress, modName);
            slowRegistry.register(modAddress, modName);

            assertEq(fastRegistry.searchByName(modName), modAddress);
            assertEq(fastRegistry.searchByAddress(modAddress), modName);

            assertEq(slowRegistry.searchByName(modName), modAddress);
            assertEq(slowRegistry.searchByAddress(modAddress), modName);
        } else {
            vm.expectRevert();
            fastRegistry.register(modAddress, modName);

            vm.expectRevert();
            slowRegistry.register(modAddress, modName);

            assertEq(fastRegistry.searchByName(modName), address(0x0));
            assertEq(fastRegistry.searchByAddress(modAddress), "");

            assertEq(slowRegistry.searchByName(modName), address(0x0));
            assertEq(slowRegistry.searchByAddress(modAddress), "");
        }

        vm.stopPrank();
    }
}
