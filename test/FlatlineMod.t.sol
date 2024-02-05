// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

import { Test } from "../lib/forge-std/src/Test.sol";

import { FlatlineMod } from "../src/mods/FlatlineMod.sol";

contract FlatlineModTest is Test {
    FlatlineMod internal flatlineMod;
    address internal alice = vm.addr(1);
    address internal bob = vm.addr(2);
    uint32 internal defaultInterval = 1;
    bytes32 internal flatlineSlot = bytes32(uint256(keccak256("EtherDeckMk2.FlatlineSlot")) - 1);

    function setUp() public {
        flatlineMod = new FlatlineMod();
    }

    function testSetContingency() public {
        setRunner(alice);

        assertEq(bytes32(0), vm.load(address(flatlineMod), flatlineSlot));

        vm.prank(alice);
        flatlineMod.setContingency(bob, defaultInterval);

        bytes32 value = bytes32(uint256(uint160(bob)) << 96 | uint256(defaultInterval) << 64 | uint256(block.timestamp));

        assertEq(value, vm.load(address(flatlineMod), flatlineSlot));
    }

    function testSetContingencyNotRunner() public {
        setRunner(alice);

        vm.expectRevert();

        vm.prank(bob);
        flatlineMod.setContingency(bob, defaultInterval);
    }

    function testCheckIn() public {
        setRunner(alice);

        vm.prank(alice);
        flatlineMod.setContingency(bob, defaultInterval);

        bytes32 value = bytes32(uint256(uint160(bob)) << 96 | uint256(defaultInterval) << 64 | uint256(block.timestamp));

        assertEq(value, vm.load(address(flatlineMod), flatlineSlot));

        vm.warp(block.timestamp + 1);

        vm.prank(alice);
        flatlineMod.checkIn();

        bytes32 newValue =
            bytes32(uint256(uint160(bob)) << 96 | uint256(defaultInterval) << 64 | uint256(block.timestamp));

        assertEq(newValue, vm.load(address(flatlineMod), flatlineSlot));
    }

    function testCheckInNotRunner() public {
        setRunner(alice);

        vm.prank(alice);
        flatlineMod.setContingency(bob, defaultInterval);

        vm.expectRevert();

        vm.prank(bob);
        flatlineMod.checkIn();
    }

    function testContingency() public {
        setRunner(alice);

        vm.prank(alice);
        flatlineMod.setContingency(bob, defaultInterval);

        bytes32 value = bytes32(uint256(uint160(bob)) << 96 | uint256(defaultInterval) << 64 | uint256(block.timestamp));

        assertEq(value, vm.load(address(flatlineMod), flatlineSlot));

        vm.warp(block.timestamp + 1);

        vm.prank(alice);
        flatlineMod.contingency();

        assertEq(bytes32(uint256(uint160(bob))), vm.load(address(flatlineMod), bytes32(uint256(1))));
        assertEq(bytes32(0), vm.load(address(flatlineMod), flatlineSlot));
    }

    function testContingencyDeadlineNotPassed() public {
        setRunner(alice);

        vm.prank(alice);
        flatlineMod.setContingency(bob, defaultInterval);

        bytes32 value = bytes32(uint256(uint160(bob)) << 96 | uint256(defaultInterval) << 64 | uint256(block.timestamp));

        assertEq(value, vm.load(address(flatlineMod), flatlineSlot));

        vm.expectRevert();

        vm.prank(alice);
        flatlineMod.contingency();
    }

    function testContingencyZeroInterval() public {
        setRunner(alice);

        vm.prank(alice);
        flatlineMod.setContingency(bob, 0);

        bytes32 value = bytes32(uint256(uint160(bob)) << 96 | uint256(0) << 64 | uint256(block.timestamp));

        assertEq(value, vm.load(address(flatlineMod), flatlineSlot));

        vm.expectRevert();

        vm.prank(alice);
        flatlineMod.contingency();
    }

    function testContingencyNotRunner() public {
        setRunner(alice);

        vm.prank(alice);
        flatlineMod.setContingency(bob, defaultInterval);

        bytes32 value = bytes32(uint256(uint160(bob)) << 96 | uint256(defaultInterval) << 64 | uint256(block.timestamp));

        assertEq(value, vm.load(address(flatlineMod), flatlineSlot));

        vm.warp(block.timestamp + 1);

        vm.prank(bob);
        flatlineMod.contingency();

        assertEq(bytes32(uint256(uint160(bob))), vm.load(address(flatlineMod), bytes32(uint256(1))));
        assertEq(bytes32(0), vm.load(address(flatlineMod), flatlineSlot));
    }

    function testFuzzSetContingency(
        bool runnerIsActor,
        address runner,
        address actor,
        address receiver,
        uint32 interval,
        uint64 startTime
    ) public {
        runner = runnerIsActor ? actor : runner;

        vm.warp(startTime);

        setRunner(runner);

        assertEq(bytes32(0), vm.load(address(flatlineMod), flatlineSlot));

        if (runner != actor) {
            vm.expectRevert();
        }

        vm.prank(actor);
        flatlineMod.setContingency(receiver, interval);

        if (runner == actor) {
            bytes32 value = bytes32(uint256(uint160(receiver)) << 96 | uint256(interval) << 64 | uint256(startTime));
            assertEq(value, vm.load(address(flatlineMod), flatlineSlot));
        }
    }

    function testFuzzCheckIn(
        bool runnerIsActor,
        address runner,
        address actor,
        address receiver,
        uint32 interval,
        uint64 startTime
    ) public {
        startTime = uint64(bound(startTime, 0, type(uint64).max - interval));
        runner = runnerIsActor ? actor : runner;

        vm.warp(startTime);

        setRunner(runner);

        vm.prank(runner);
        flatlineMod.setContingency(receiver, interval);

        if (runner != actor) {
            vm.expectRevert();
        }

        vm.warp(startTime + interval);

        vm.prank(actor);
        flatlineMod.checkIn();

        if (runner == actor) {
            bytes32 value =
                bytes32(uint256(uint160(receiver)) << 96 | uint256(interval) << 64 | uint256(startTime + interval));
            assertEq(value, vm.load(address(flatlineMod), flatlineSlot));
        }
    }

    function testFuzzContingency(
        bool runnerIsActor,
        address runner,
        address actor,
        address receiver,
        uint32 interval,
        uint64 startTime,
        uint64 contingencyTime
    ) public {
        startTime = uint64(bound(startTime, 0, type(uint32).max));
        contingencyTime = uint64(bound(contingencyTime, startTime, type(uint64).max));
        runner = runnerIsActor ? actor : runner;

        vm.warp(startTime);

        setRunner(runner);

        vm.prank(runner);
        flatlineMod.setContingency(receiver, interval);

        vm.warp(contingencyTime);

        if (contingencyTime < interval + startTime || interval == 0) {
            vm.expectRevert();
        }

        vm.prank(actor);
        flatlineMod.contingency();

        if (runner == actor && contingencyTime >= interval + startTime && interval != 0) {
            assertEq(bytes32(0), vm.load(address(flatlineMod), flatlineSlot));
            assertEq(bytes32(uint256(uint160(receiver))), vm.load(address(flatlineMod), bytes32(uint256(1))));
        }
    }

    function setRunner(address runner) internal {
        vm.store(address(flatlineMod), bytes32(uint256(1)), bytes32(uint256(uint160(runner))));
    }
}
