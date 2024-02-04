// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import { Test } from "../../lib/forge-std/src/Test.sol";

import { TwoStepTransitionMod } from "../../src/mods/TwoStepTransitionMod.sol";
import { DifferentialTwoStepTransitionMod } from "./implementations/DifferentialTwoStepTransitionMod.sol";

contract DifferentialTwoStepTransitionModTest is Test {
    TwoStepTransitionMod internal fastTwoStepMod;
    DifferentialTwoStepTransitionMod internal slowTwoStepMod;

    bytes32 internal NewRunnerSlot = bytes32(uint256(keccak256("EtherDeckMk2.NewRunner")) - 1);

    function setUp() public {
        fastTwoStepMod = new TwoStepTransitionMod();
        slowTwoStepMod = new DifferentialTwoStepTransitionMod();
    }

    function testFuzzStartRunnerTransition(
        bool runnerIsActor,
        address runner,
        address actor,
        address newRunner
    ) public {
        runner = runnerIsActor ? actor : runner;

        setRunner(runner);

        vm.startPrank(actor);

        if (runner != actor) {
            vm.expectRevert();
            fastTwoStepMod.startRunnerTransition(newRunner);

            vm.expectRevert();
            slowTwoStepMod.startRunnerTransition(newRunner);
        } else {
            fastTwoStepMod.startRunnerTransition(newRunner);
            slowTwoStepMod.startRunnerTransition(newRunner);

            assertEq(vm.load(address(fastTwoStepMod), bytes32(uint256(1))), bytes32(uint256(uint160(runner))));
            assertEq(vm.load(address(fastTwoStepMod), NewRunnerSlot), bytes32(uint256(uint160(newRunner))));
            assertEq(vm.load(address(slowTwoStepMod), bytes32(uint256(1))), bytes32(uint256(uint160(runner))));
            assertEq(vm.load(address(slowTwoStepMod), NewRunnerSlot), bytes32(uint256(uint160(newRunner))));
        }

        vm.stopPrank();
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
        fastTwoStepMod.startRunnerTransition(newRunner);

        vm.prank(runner);
        slowTwoStepMod.startRunnerTransition(newRunner);

        vm.startPrank(actor);

        if (actor != newRunner) {
            vm.expectRevert();
            fastTwoStepMod.acceptRunnerTransition();

            vm.expectRevert();
            slowTwoStepMod.acceptRunnerTransition();
        } else {
            fastTwoStepMod.acceptRunnerTransition();
            slowTwoStepMod.acceptRunnerTransition();

            assertEq(vm.load(address(fastTwoStepMod), bytes32(uint256(1))), bytes32(uint256(uint160(newRunner))));
            assertEq(vm.load(address(slowTwoStepMod), bytes32(uint256(1))), bytes32(uint256(uint160(newRunner))));
        }

    }

    function setRunner(address runner) internal {
        vm.store(address(fastTwoStepMod), bytes32(uint256(1)), bytes32(uint256(uint160(runner))));
        vm.store(address(slowTwoStepMod), bytes32(uint256(1)), bytes32(uint256(uint160(runner))));
    }
}
