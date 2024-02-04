// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import { Test } from "../lib/forge-std/src/Test.sol";

import { StorageMod } from "../src/mods/StorageMod.sol";

contract StorageModTest is Test {
    StorageMod storageMod;

    address internal alice = vm.addr(1);
    address internal bob = vm.addr(2);
    bytes32 internal defaultSlot = bytes32(uint256(3));
    bytes32 internal defaultValue = bytes32(uint256(1));
    bytes32 internal empty = bytes32(uint256(0));

    function setUp() public {
        storageMod = new StorageMod();
    }

    function testWriteSingle() public {
        setRunner(alice);

        assertEq(vm.load(address(storageMod), defaultSlot), empty);

        bytes32[] memory slots = new bytes32[](1);
        slots[0] = defaultSlot;

        bytes32[] memory values = new bytes32[](1);
        values[0] = defaultValue;

        vm.prank(alice);
        storageMod.write(slots, values);

        assertEq(vm.load(address(storageMod), defaultSlot), defaultValue);
    }

    function testWriteDouble() public {
        setRunner(alice);

        bytes32[] memory slots = new bytes32[](2);
        slots[0] = defaultSlot;
        slots[1] = bytes32(uint256(defaultSlot) + 1);

        bytes32[] memory values = new bytes32[](2);
        values[0] = defaultValue;
        values[1] = bytes32(uint256(defaultValue) + 1);

        vm.prank(alice);
        storageMod.write(slots, values);

        assertEq(vm.load(address(storageMod), defaultSlot), defaultValue);
        assertEq(vm.load(address(storageMod), bytes32(uint256(defaultSlot) + 1)), bytes32(uint256(defaultValue) + 1));
    }

    function testWriteEmpty() public {
        setRunner(alice);

        vm.prank(alice);
        storageMod.write(new bytes32[](0), new bytes32[](0));
    }

    function testWriteNotRunner() public {
        setRunner(alice);

        vm.expectRevert();

        vm.prank(bob);
        storageMod.write(new bytes32[](0), new bytes32[](0));
    }

    function testWriteLengthMismatch() public {
        setRunner(alice);

        vm.expectRevert();

        vm.prank(alice);
        storageMod.write(new bytes32[](0), new bytes32[](1));
    }

    function testReadSingle() public {
        setRunner(alice);

        vm.store(address(storageMod), defaultSlot, defaultValue);

        bytes32[] memory slots = new bytes32[](1);
        slots[0] = defaultSlot;

        vm.prank(alice);
        bytes32[] memory values = storageMod.read(slots);

        assertEq(values[0], defaultValue);
    }

    function testReadDouble() public {
        setRunner(alice);

        vm.store(address(storageMod), defaultSlot, defaultValue);
        vm.store(address(storageMod), bytes32(uint256(defaultSlot) + 1), bytes32(uint256(defaultValue) + 1));

        bytes32[] memory slots = new bytes32[](2);
        slots[0] = defaultSlot;
        slots[1] = bytes32(uint256(defaultSlot) + 1);

        vm.prank(alice);
        bytes32[] memory values = storageMod.read(slots);

        assertEq(values.length, 2);
        assertEq(values[0], defaultValue);
        assertEq(values[1], bytes32(uint256(defaultValue) + 1));
    }

    function testReadEmpty() public {
        setRunner(alice);

        vm.prank(alice);
        bytes32[] memory values = storageMod.read(new bytes32[](0));

        assertEq(values.length, 0);
    }

    function testReadNotRunner() public {
        setRunner(alice);

        vm.prank(bob);
        storageMod.read(new bytes32[](0));
    }

    function testFuzzWrite(
        bool runnerIsActor,
        address runner,
        address actor,
        bool lengthMismatch,
        bytes32[] memory slots
    ) public {
        runner = runnerIsActor ? actor : runner;

        setRunner(runner);

        bytes32[] memory values = new bytes32[](lengthMismatch ? slots.length + 1 : slots.length);

        for (uint256 i; i < slots.length; i++) {
            values[i] = keccak256(abi.encode(slots[i]));
        }

        if (lengthMismatch || runner != actor) {
            vm.expectRevert();
        }

        vm.prank(actor);
        storageMod.write(slots, values);

        if (!lengthMismatch && actor == runner) {
            for (uint256 i; i < slots.length; i++) {
                assertEq(vm.load(address(storageMod), slots[i]), bytes32(values[i]));
            }
        }
    }

    function testFuzzRead(bytes32[] memory slots) public {
        bytes32[] memory values = new bytes32[](slots.length);
        for (uint256 i; i < slots.length; i++) {
            values[i] = keccak256(abi.encode(slots[i]));
            vm.store(address(storageMod), slots[i], values[i]);
        }

        bytes32[] memory returnedValues = storageMod.read(slots);

        assertEq(returnedValues.length, slots.length);
        for (uint256 i; i < slots.length; i++) {
            assertEq(returnedValues[i], values[i]);
        }
    }

    function setRunner(address runner) public {
        vm.store(address(storageMod), bytes32(uint256(1)), bytes32(uint256(uint160(runner))));
    }
}
