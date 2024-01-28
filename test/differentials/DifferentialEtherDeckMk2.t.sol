// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import { Test, console } from "../../lib/forge-std/src/Test.sol";

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
        address target,
        uint256 value,
        bytes calldata payload
    ) public {
        runner = runnerIsActor ? actor : runner;
        runner = boundAddy(runner);
        actor = boundAddy(actor);
        target = boundAddy(target);
        value = bound(value, 0, type(uint256).max / 2);

        setRunner(runner);
        vm.deal(actor, value * 2);

        vm.startPrank(actor);

        try fastDeck.run{ value: value }(target, payload) {
            slowDeck.run{ value: value }(target, payload);

            assertEq(actor.balance, 0);
            assertEq(address(fastDeck).balance, 0);
            assertEq(address(slowDeck).balance, 0);
            assertEq(target.balance, value * 2);
        } catch {
            vm.expectRevert();
            slowDeck.run{ value: value }(target, payload);
        }

        vm.stopPrank();
    }

    function testFuzzDiffRunBatch(
        bool runnerIsActor,
        address runner,
        address actor,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory payloads
    ) public {
        runner = runnerIsActor ? actor : runner;
        runner = boundAddy(runner);
        actor = boundAddy(actor);

        for (uint256 i; i < targets.length; i++) {
            targets[i] = boundAddy(targets[i]);
        }

        uint256 totalValue;
        for (uint256 i; i < values.length; i++) {
            totalValue += values[i] = bound(values[i], 0, type(uint96).max);
        }

        setRunner(runner);
        vm.deal(actor, totalValue);

        vm.startPrank(actor);

        try fastDeck.runBatch{ value: totalValue }(targets, values, payloads) {
            slowDeck.runBatch{ value: totalValue }(targets, values, payloads);

            assertEq(actor.balance, 0);
            assertEq(address(fastDeck).balance, 0);
            assertEq(address(slowDeck).balance, 0);
            for (uint256 i; i < targets.length; i++) {
                assertEq(targets[i].balance, values[i]);
            }
        } catch {
            vm.expectRevert();
            slowDeck.runBatch{ value: totalValue }(targets, values, payloads);
        }

        vm.stopPrank();
    }

    function testFuzzDiffRunFrom(
        bool runnerIsActor,
        uint256 runnerPk,
        address actor,
        address target,
        uint256 value,
        uint256 bribe,
        bytes calldata payload,
        bool validSig,
        bytes calldata invalidSigdata
    ) public {
        runnerPk = boundPk(runnerPk);
        actor = runnerIsActor ? vm.addr(runnerPk) : actor;

        actor = boundAddy(actor);
        target = boundAddy(target);
        value = bound(value, 0, type(uint256).max / 4);
        bribe = bound(bribe, 0, type(uint256).max / 4);

        setRunner(vm.addr(runnerPk));
        vm.deal(actor, value * 2);
        vm.deal(address(fastDeck), bribe);
        vm.deal(address(slowDeck), bribe);

        bytes32 sighash = keccak256(abi.encodePacked(payload, uint256(uint160(target)), value, bribe, fastDeck.nonce()));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(runnerPk, sighash);
        bytes memory sigdata = validSig ? abi.encode(sighash, v, r, s) : invalidSigdata;

        vm.startPrank(actor);

        try fastDeck.runFrom{ value: value }(target, payload, sigdata, bribe) {
            slowDeck.runFrom{ value: value }(target, payload, sigdata, bribe);

            if (actor != target) {
                assertEq(actor.balance, bribe * 2);
                assertEq(target.balance, value * 2);
            } else {
                assertEq(actor.balance, bribe * 2 + value * 2);
            }

            assertEq(address(fastDeck).balance, 0);
            assertEq(address(slowDeck).balance, 0);
        } catch {
            vm.expectRevert();
            slowDeck.runFrom{ value: value }(target, payload, sigdata, bribe);
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

    function boundPk(uint256 pk) internal pure returns (uint256) {
        return bound(pk, 1, 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140);
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
