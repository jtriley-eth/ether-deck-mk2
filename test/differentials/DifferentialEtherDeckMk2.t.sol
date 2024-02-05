// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

import { Test } from "../../lib/forge-std/src/Test.sol";

import { EtherDeckMk2 } from "../../src/EtherDeckMk2.sol";
import { DifferentialEtherDeckMk2 } from "./implementations/DifferentialEtherDeckMk2.sol";
import { MockTarget } from "../mock/MockTarget.sol";

contract DifferentialEtherDeckMk2Test is Test {
    EtherDeckMk2 internal fastDeck;
    DifferentialEtherDeckMk2 internal slowDeck;

    function setUp() public {
        fastDeck = new EtherDeckMk2();
        slowDeck = new DifferentialEtherDeckMk2();
    }

    function testFuzzDiffRun(
        bool runnerIsActor,
        address runner,
        address actor,
        bytes32 salt,
        uint256 value,
        bytes calldata payload,
        bool throws
    ) public {
        address target = address(new MockTarget{ salt: salt }());

        MockTarget(payable(target)).setThrows(throws);

        runner = runnerIsActor ? actor : runner;
        value = bound(value, 0, type(uint256).max / 2);

        setRunner(runner);
        vm.deal(actor, value * 2);

        vm.startPrank(actor);

        if (throws || runner != actor) {
            vm.expectRevert();
            fastDeck.run{ value: value }(target, payload);

            vm.expectRevert();
            slowDeck.run{ value: value }(target, payload);
        } else {
            fastDeck.run{ value: value }(target, payload);
            slowDeck.run{ value: value }(target, payload);

            assertEq(actor.balance, 0);
            assertEq(address(fastDeck).balance, 0);
            assertEq(address(slowDeck).balance, 0);
            assertEq(target.balance, value * 2);
        }

        vm.stopPrank();
    }

    function testFuzzDiffRunBatch(
        bool runnerIsActor,
        address runner,
        address actor,
        bytes32 salt,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory payloads,
        bool throws
    ) public {
        runner = runnerIsActor ? actor : runner;

        for (uint256 i; i < targets.length; i++) {
            targets[i] = address(new MockTarget{ salt: salt }());
            MockTarget(payable(targets[i])).setThrows(throws);
            salt = keccak256(abi.encode(salt));
        }

        uint256 totalValue;
        for (uint256 i; i < values.length; i++) {
            totalValue += values[i] = bound(values[i], 0, type(uint96).max);
        }

        setRunner(runner);
        vm.deal(actor, totalValue * 2);

        vm.startPrank(actor);

        if (throws || targets.length != values.length || targets.length != payloads.length && targets.length != 0) {
            vm.expectRevert();
            fastDeck.runBatch(targets, values, payloads);

            vm.expectRevert();
            slowDeck.runBatch(targets, values, payloads);
        } else {
            fastDeck.runBatch{ value: totalValue }(targets, values, payloads);
            slowDeck.runBatch{ value: totalValue }(targets, values, payloads);

            assertEq(actor.balance, 0);
            assertEq(address(fastDeck).balance, 0);
            assertEq(address(slowDeck).balance, 0);

            for (uint256 i; i < targets.length; i++) {
                assertEq(targets[i].balance, values[i] * 2);
            }
        }

        vm.stopPrank();
    }

    function testFuzzDiffSetDispatch(
        bool runnerIsActor,
        address runner,
        address actor,
        bytes4 selector,
        address target
    ) public {
        runner = runnerIsActor ? actor : runner;
        setRunner(runner);

        vm.startPrank(runner);
        fastDeck.setDispatch(selector, target);
        slowDeck.setDispatch(selector, target);
        vm.stopPrank();

        assertEq(fastDeck.dispatch(selector), target);
        assertEq(slowDeck.dispatch(selector), target);
    }

    function testFuzzDiffSetDispatchBatch(
        bool runnerIsActor,
        address runner,
        address actor,
        address[] memory targets,
        bool lengthMismatch
    ) public {
        runner = runnerIsActor ? actor : runner;
        setRunner(runner);

        bytes4[] memory selectors = new bytes4[](lengthMismatch ? targets.length + 1 : targets.length);

        for (uint256 i; i < selectors.length; i++) {
            selectors[i] = bytes4(keccak256(abi.encode(i)));
        }

        bool selectorCollision;
        for (uint256 i; i < selectors.length; i++) {
            for (uint256 j; j < selectors.length; j++) {
                if (i != j && selectors[i] == selectors[j]) {
                    selectorCollision = true;
                }
            }
        }
        vm.assume(!selectorCollision);

        vm.startPrank(actor);

        if (lengthMismatch || runner != actor) {
            vm.expectRevert();
            fastDeck.setDispatchBatch(selectors, targets);

            vm.expectRevert();
            slowDeck.setDispatchBatch(selectors, targets);
        } else {
            fastDeck.setDispatchBatch(selectors, targets);
            slowDeck.setDispatchBatch(selectors, targets);

            for (uint256 i; i < targets.length; i++) {
                assertEq(fastDeck.dispatch(selectors[i]), targets[i]);
                assertEq(slowDeck.dispatch(selectors[i]), targets[i]);
            }
        }

        vm.stopPrank();
    }

    function testFuzzDiffDispatch(
        bool runnerIsActor,
        address runner,
        address actor,
        bytes4 selector,
        address target
    ) public {
        runner = runnerIsActor ? actor : runner;
        target = boundAddy(target);
        setRunner(runner);

        vm.startPrank(runner);

        fastDeck.setDispatch(selector, target);
        slowDeck.setDispatch(selector, target);
        vm.stopPrank();

        (bool fastSucc, bytes memory fastret) = address(fastDeck).call(abi.encodeWithSelector(selector));
        (bool slowSucc, bytes memory slowret) = address(slowDeck).call(abi.encodeWithSelector(selector));

        assertEq(fastSucc, slowSucc);
        assertEq(keccak256(fastret), keccak256(slowret));
    }

    function setRunner(address runner) internal {
        vm.store(address(fastDeck), bytes32(uint256(1)), bytes32(uint256(uint160(runner))));
        vm.store(address(slowDeck), bytes32(uint256(1)), bytes32(uint256(uint160(runner))));
    }

    function boundAddy(address addy) internal view returns (address) {
        if (
            uint160(addy) < 256 || addy == address(fastDeck) || addy == address(slowDeck)
                || addy == 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D || addy == 0x000000000000000000636F6e736F6c652e6c6f67
                || addy == 0x4e59b44847b379578588920cA78FbF26c0B4956C
        ) addy = address(uint160(addy) + 256);
        return addy;
    }
}
