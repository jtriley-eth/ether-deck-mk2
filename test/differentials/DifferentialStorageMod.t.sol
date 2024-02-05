// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

import { Test } from "../../lib/forge-std/src/Test.sol";

import { StorageMod } from "../../src/mods/StorageMod.sol";
import { DifferentialStorageMod } from "./implementations/DifferentialStorageMod.sol";

contract DifferentialStorageModTest is Test {
    StorageMod internal fastStorageMod;
    DifferentialStorageMod internal slowStorageMod;

    function setUp() public {
        fastStorageMod = new StorageMod();
        slowStorageMod = new DifferentialStorageMod();
    }

    function testFuzzDiffWrite(
        bool runnerIsActor,
        address runner,
        address actor,
        bool lengthMismatch,
        bytes32[] memory slots
    ) public {
        runner = runnerIsActor ? actor : runner;

        vm.store(address(fastStorageMod), bytes32(uint256(1)), bytes32(uint256(uint160(runner))));
        vm.store(address(slowStorageMod), bytes32(uint256(1)), bytes32(uint256(uint160(runner))));

        bytes32[] memory values = new bytes32[](lengthMismatch ? slots.length + 1 : slots.length);

        for (uint256 i = 0; i < slots.length; i++) {
            values[i] = keccak256(abi.encode(slots[i]));
        }

        vm.startPrank(actor);

        if (lengthMismatch || runner != actor) {
            vm.expectRevert();
            fastStorageMod.write(slots, values);

            vm.expectRevert();
            slowStorageMod.write(slots, values);
        } else {
            fastStorageMod.write(slots, values);
            slowStorageMod.write(slots, values);

            for (uint256 i = 0; i < slots.length; i++) {
                assertEq(vm.load(address(fastStorageMod), slots[i]), values[i]);
                assertEq(vm.load(address(slowStorageMod), slots[i]), values[i]);
            }
        }
    }

    function testFuzzDiffRead(bytes32[] memory slots) public {
        bytes32[] memory values = new bytes32[](slots.length);

        for (uint256 i = 0; i < slots.length; i++) {
            values[i] = keccak256(abi.encode(slots[i]));
            vm.store(address(fastStorageMod), slots[i], values[i]);
            vm.store(address(slowStorageMod), slots[i], values[i]);
        }

        bytes32[] memory fastValues = fastStorageMod.read(slots);
        bytes32[] memory slowValues = slowStorageMod.read(slots);

        for (uint256 i = 0; i < slots.length; i++) {
            assertEq(fastValues[i], values[i]);
            assertEq(slowValues[i], values[i]);
        }
    }
}
