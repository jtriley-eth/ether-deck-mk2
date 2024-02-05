// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import { Test } from "../../lib/forge-std/src/Test.sol";

import { BribeMod } from "../../src/mods/BribeMod.sol";
import { DifferentialBribeMod } from "./implementations/DifferentialBribeMod.sol";
import { MockTarget } from "../mock/MockTarget.sol";

contract DifferentialBribeModTest is Test {
    BribeMod internal fastBribeMod;
    DifferentialBribeMod internal slowBribeMod;

    function setUp() public {
        fastBribeMod = new BribeMod();
        slowBribeMod = new DifferentialBribeMod();
    }

    function testFuzzDiffBribeBuilder(
        bool runnerIsActor,
        address runner,
        address actor,
        bytes32 salt,
        bytes calldata payload,
        uint256 value,
        uint256 bribe,
        bool targetThrows
    ) public {
        value = bound(value, 0, type(uint256).max / 4);
        bribe = bound(bribe, 0, type(uint256).max / 4);
        address coinbase = address(bytes20(keccak256(abi.encode(salt))));
        runner = runnerIsActor ? actor : runner;
        setRunner(runner);

        MockTarget target = new MockTarget{ salt: salt }();

        target.setThrows(targetThrows);

        vm.deal(actor, value * 2);
        vm.deal(address(fastBribeMod), bribe);
        vm.deal(address(slowBribeMod), bribe);

        vm.coinbase(coinbase);

        vm.startPrank(actor);

        if (runner != actor || targetThrows) {
            vm.expectRevert();
            fastBribeMod.bribeBuilder{ value: value }(address(target), payload, bribe);

            vm.expectRevert();
            slowBribeMod.bribeBuilder{ value: value }(address(target), payload, bribe);
        } else {
            fastBribeMod.bribeBuilder{ value: value }(address(target), payload, bribe);
            slowBribeMod.bribeBuilder{ value: value }(address(target), payload, bribe);

            assertEq(actor.balance, 0);
            assertEq(coinbase.balance, bribe * 2);
            assertEq(address(fastBribeMod).balance, 0);
            assertEq(address(slowBribeMod).balance, 0);
            assertEq(address(target).balance, value * 2);
        }

        vm.stopPrank();
    }

    function testFuzzDiffBribeCaller(
        bool runnerIsActor,
        address runner,
        uint256 actorPk,
        bytes32 salt,
        uint256 value,
        uint256 bribe,
        bytes calldata payload,
        bool validSig,
        bytes calldata invalidSigdata
    ) public {
        actorPk = boundPk(actorPk);
        address actor = vm.addr(actorPk);
        address caller = address(bytes20(keccak256(abi.encode(salt))));
        runner = runnerIsActor ? actor : runner;

        address target = address(new MockTarget{ salt: salt }());
        value = bound(value, 0, type(uint256).max / 4);
        bribe = bound(bribe, 0, type(uint256).max / 4);

        setRunner(runner);
        vm.deal(caller, value * 2);
        vm.deal(address(fastBribeMod), bribe);
        vm.deal(address(slowBribeMod), bribe);

        bytes32 sighash = keccak256(abi.encodePacked(payload, uint256(uint160(target)), value, bribe, fastBribeMod.nonce()));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(actorPk, sighash);
        bytes memory sigdata = abi.encode(sighash, v, r, s);
        if (!validSig) {
            sigdata = keccak256(invalidSigdata) == keccak256(sigdata)
                ? abi.encodePacked(invalidSigdata, uint8(0xff))
                : invalidSigdata;
        }

        vm.startPrank(caller);

        if (validSig && actor == runner) {
            fastBribeMod.bribeCaller{ value: value }(target, payload, sigdata, bribe);
            slowBribeMod.bribeCaller{ value: value }(target, payload, sigdata, bribe);

            assertEq(actor.balance, 0);
            assertEq(caller.balance, bribe * 2);
            assertEq(address(fastBribeMod).balance, 0);
            assertEq(address(slowBribeMod).balance, 0);
            assertEq(target.balance, value * 2);
        } else {
            vm.expectRevert();
            fastBribeMod.bribeCaller{ value: value }(target, payload, sigdata, bribe);

            vm.expectRevert();
            slowBribeMod.bribeCaller{ value: value }(target, payload, sigdata, bribe);
        }

        vm.stopPrank();
    }

    function boundPk(uint256 pk) internal pure returns (uint256) {
        return bound(pk, 1, 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140);
    }

    function setRunner(address runner) internal {
        vm.store(address(fastBribeMod), bytes32(uint256(1)), bytes32(uint256(uint160(runner))));
        vm.store(address(slowBribeMod), bytes32(uint256(1)), bytes32(uint256(uint160(runner))));
    }
}
