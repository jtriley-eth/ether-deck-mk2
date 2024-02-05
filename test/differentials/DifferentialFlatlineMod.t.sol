// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

import { Test } from "../../lib/forge-std/src/Test.sol";

import { FlatlineMod } from "../../src/mods/FlatlineMod.sol";
import { DifferentialFlatlineMod } from "../differentials/implementations/DifferentialFlatlineMod.sol";

contract DifferentialFlatlineModTest is Test {
    FlatlineMod internal fastFlatlineMod;
    DifferentialFlatlineMod internal slowFlatlineMod;

    bytes32 internal flatlineSlot = bytes32(uint256(keccak256("EtherDeckMk2.FlatlineSlot")) - 1);

    function setUp() public {
        fastFlatlineMod = new FlatlineMod();
        slowFlatlineMod = new DifferentialFlatlineMod();
    }

    function testFuzzDiffSetContingency(
        bool runnerIsActor,
        address runner,
        address actor,
        address receiver,
        uint32 interval,
        uint64 startTime
    ) public {
        startTime = uint64(bound(startTime, 0, type(uint32).max));
        runner = runnerIsActor ? actor : runner;

        vm.warp(startTime);

        setRunner(runner);

        assertEq(bytes32(0), vm.load(address(fastFlatlineMod), flatlineSlot));
        assertEq(bytes32(0), vm.load(address(slowFlatlineMod), flatlineSlot));

        vm.startPrank(actor);

        if (runner != actor) {
            vm.expectRevert();
            fastFlatlineMod.setContingency(receiver, interval);

            vm.expectRevert();
            slowFlatlineMod.setContingency(receiver, interval);
        } else {
            fastFlatlineMod.setContingency(receiver, interval);
            slowFlatlineMod.setContingency(receiver, interval);

            bytes32 value = bytes32(uint256(uint160(receiver)) << 96 | uint256(interval) << 64 | uint256(startTime));

            assertEq(value, vm.load(address(fastFlatlineMod), flatlineSlot));
            assertEq(value, vm.load(address(slowFlatlineMod), flatlineSlot));
        }

        vm.stopPrank();
    }

    function testFuzzDiffCheckIn(
        bool runnerIsActor,
        address runner,
        address actor,
        address receiver,
        uint32 interval,
        uint64 startTime
    ) public {
        startTime = uint64(bound(startTime, 0, type(uint32).max));
        runner = runnerIsActor ? actor : runner;

        vm.warp(startTime);

        setRunner(runner);

        vm.prank(runner);
        fastFlatlineMod.setContingency(receiver, interval);

        vm.prank(runner);
        slowFlatlineMod.setContingency(receiver, interval);

        bytes32 value = bytes32(uint256(uint160(receiver)) << 96 | uint256(interval) << 64 | uint256(startTime));

        assertEq(value, vm.load(address(fastFlatlineMod), flatlineSlot));
        assertEq(value, vm.load(address(slowFlatlineMod), flatlineSlot));

        vm.warp(startTime + interval);

        vm.startPrank(actor);

        if (runner != actor) {
            vm.expectRevert();
            fastFlatlineMod.checkIn();

            vm.expectRevert();
            slowFlatlineMod.checkIn();
        } else {
            fastFlatlineMod.checkIn();
            slowFlatlineMod.checkIn();

            bytes32 newValue =
                bytes32(uint256(uint160(receiver)) << 96 | uint256(interval) << 64 | uint256(startTime + interval));

            assertEq(newValue, vm.load(address(fastFlatlineMod), flatlineSlot));
            assertEq(newValue, vm.load(address(slowFlatlineMod), flatlineSlot));
        }

        vm.stopPrank();
    }

    function testFuzzDiffContingency(
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
        fastFlatlineMod.setContingency(receiver, interval);

        vm.prank(runner);
        slowFlatlineMod.setContingency(receiver, interval);

        vm.warp(contingencyTime);

        vm.startPrank(actor);

        if (contingencyTime < interval + startTime || interval == 0) {
            vm.expectRevert();
            fastFlatlineMod.contingency();

            vm.expectRevert();
            slowFlatlineMod.contingency();
        } else {
            fastFlatlineMod.contingency();
            slowFlatlineMod.contingency();

            bytes32 value = bytes32(0);

            assertEq(value, vm.load(address(fastFlatlineMod), flatlineSlot));
            assertEq(value, vm.load(address(slowFlatlineMod), flatlineSlot));
        }

        vm.stopPrank();
    }

    function setRunner(address runner) internal {
        vm.store(address(fastFlatlineMod), bytes32(uint256(1)), bytes32(uint256(uint160(runner))));
        vm.store(address(slowFlatlineMod), bytes32(uint256(1)), bytes32(uint256(uint160(runner))));
    }
}
