// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

import { Test } from "../lib/forge-std/src/Test.sol";

import { TwoStepTransitionMod } from "../src/mods/TwoStepTransitionMod.sol";

contract TwoStepTransitionModTest is Test {
    TwoStepTransitionMod twoStepMod;

    address internal alice = vm.addr(1);
    address internal bob = vm.addr(2);

    bytes32 internal NewRunnerSlot = bytes32(uint256(keccak256("EtherDeckMk2.TwoStepTransitionMod.newRunner")) - 1);

    function setUp() public {
        twoStepMod = new TwoStepTransitionMod();
    }

    function testStartRunnerTransition() public {
        setRunner(alice);

        vm.prank(alice);
        twoStepMod.startRunnerTransition(bob);

        assertEq(vm.load(address(twoStepMod), bytes32(uint256(1))), bytes32(uint256(uint160(alice))));
        assertEq(vm.load(address(twoStepMod), NewRunnerSlot), bytes32(uint256(uint160(bob))));
    }

    function testStartRunnerTransitionNotRunner() public {
        setRunner(alice);

        vm.expectRevert();

        vm.prank(bob);
        twoStepMod.startRunnerTransition(bob);
    }

    function testAcceptRunnerTransition() public {
        setRunner(alice);

        vm.prank(alice);
        twoStepMod.startRunnerTransition(bob);

        vm.prank(bob);
        twoStepMod.acceptRunnerTransition();

        assertEq(vm.load(address(twoStepMod), bytes32(uint256(1))), bytes32(uint256(uint160(bob))));
    }

    function testAcceptRunnerTransitionNotNewRunner() public {
        setRunner(alice);

        vm.prank(alice);
        twoStepMod.startRunnerTransition(bob);

        vm.expectRevert();

        vm.prank(alice);
        twoStepMod.acceptRunnerTransition();
    }

    function testFuzzStartRunnerTransition(
        bool runnerIsActor,
        address runner,
        address actor,
        address newRunner
    ) public {
        runner = runnerIsActor ? actor : runner;

        setRunner(runner);

        if (runner != actor) {
            vm.expectRevert();
        }

        vm.prank(actor);
        twoStepMod.startRunnerTransition(newRunner);

        if (runner == actor) {
            assertEq(vm.load(address(twoStepMod), bytes32(uint256(1))), bytes32(uint256(uint160(runner))));
            assertEq(vm.load(address(twoStepMod), NewRunnerSlot), bytes32(uint256(uint160(newRunner))));
        }
    }

    function testFuzzAcceptRunnerTransition(
        bool newRunnerIsActor,
        address runner,
        address actor,
        address newRunner
    ) public {
        newRunner = newRunnerIsActor ? actor : newRunner;

        setRunner(runner);

        vm.prank(runner);
        twoStepMod.startRunnerTransition(newRunner);

        if (actor != newRunner) {
            vm.expectRevert();
        }

        vm.prank(actor);
        twoStepMod.acceptRunnerTransition();

        if (runner == newRunner) {
            assertEq(vm.load(address(twoStepMod), bytes32(uint256(1))), bytes32(uint256(uint160(newRunner))));
        }
    }

    function setRunner(address runner) internal {
        vm.store(address(twoStepMod), bytes32(uint256(1)), bytes32(uint256(uint160(runner))));
    }
}
