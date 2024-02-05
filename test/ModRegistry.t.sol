// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

import { Test } from "../lib/forge-std/src/Test.sol";

import { ModRegistry } from "../src/ModRegistry.sol";

contract ModRegistryTest is Test {
    ModRegistry internal registry;
    address internal defaultAuthority = vm.addr(1);
    address internal defaultSecondaryAuthority = vm.addr(2);
    address internal defaultUnauthorized = vm.addr(3);
    string internal defaultName = "default";
    address internal defaultAddress = address(0x45);

    function setUp() public {
        registry = new ModRegistry(defaultAuthority);
    }

    function testTransferAuthority() public {
        assertEq(registry.authority(), defaultAuthority);

        vm.expectEmit(true, true, true, true);
        emit ModRegistry.AuthorityTransferred(defaultSecondaryAuthority);

        vm.prank(defaultAuthority);
        registry.transferAuthority(defaultSecondaryAuthority);

        assertEq(registry.authority(), defaultSecondaryAuthority);
    }

    function testTransferAuthorityUnauthorized() public {
        assertEq(registry.authority(), defaultAuthority);

        vm.expectRevert();

        vm.prank(defaultUnauthorized);
        registry.transferAuthority(defaultSecondaryAuthority);
    }

    function testRegister() public {
        assertEq(registry.searchByName(defaultName), address(0x0));
        assertEq(registry.searchByAddress(defaultAddress), "");

        vm.expectEmit(true, true, true, true);
        emit ModRegistry.ModRegistered(defaultAddress, defaultName);

        vm.prank(defaultAuthority);
        registry.register(defaultAddress, defaultName);

        assertEq(registry.searchByName(defaultName), defaultAddress);
        assertEq(registry.searchByAddress(defaultAddress), defaultName);
    }

    function testRegisterUnauthorized() public {
        assertEq(registry.searchByName(defaultName), address(0x0));
        assertEq(registry.searchByAddress(defaultAddress), "");

        vm.expectRevert();

        vm.prank(defaultUnauthorized);
        registry.register(defaultAddress, defaultName);
    }

    function testRegisterNameTooLong() public {
        assertEq(registry.searchByName(defaultName), address(0x0));
        assertEq(registry.searchByAddress(defaultAddress), "");

        vm.expectRevert();

        vm.prank(defaultAuthority);
        registry.register(defaultAddress, "0123456789_0123456789_0123456789_0123456789");
    }

    function testFuzzTransferAuthority(
        bool authorityIsActorAuthority,
        address authority,
        address secondaryAuthority,
        address actor
    ) public {
        actor = authorityIsActorAuthority ? authority : actor;

        vm.prank(defaultAuthority);
        registry.transferAuthority(authority);

        if (actor == authority) {
            vm.expectEmit(true, true, true, true);
            emit ModRegistry.AuthorityTransferred(secondaryAuthority);
        } else {
            vm.expectRevert();
        }

        vm.prank(actor);
        registry.transferAuthority(secondaryAuthority);

        if (actor == authority) {
            assertEq(registry.authority(), secondaryAuthority);
        } else {
            assertEq(registry.authority(), authority);
        }
    }

    function testFuzzRegister(
        bool authorityIsActorAuthority,
        address authority,
        address actor,
        address modAddress,
        string calldata modName
    ) public {
        actor = authorityIsActorAuthority ? authority : actor;

        vm.prank(defaultAuthority);
        registry.transferAuthority(authority);

        if (actor == authority && bytes(modName).length < 32) {
            vm.expectEmit(true, true, true, true);
            emit ModRegistry.ModRegistered(modAddress, modName);
        } else {
            vm.expectRevert();
        }

        vm.prank(actor);
        registry.register(modAddress, modName);

        if (actor == authority && bytes(modName).length < 32) {
            assertEq(registry.searchByName(modName), modAddress);
            assertEq(registry.searchByAddress(modAddress), modName);
        } else {
            assertEq(registry.searchByName(modName), address(0x0));
            assertEq(registry.searchByAddress(modAddress), "");
        }
    }
}
