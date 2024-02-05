// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

import { Test } from "../lib/forge-std/src/Test.sol";

import { BribeMod } from "../src/mods/BribeMod.sol";
import { MockTarget } from "./mock/MockTarget.sol";

contract BribeModTest is Test {
    BribeMod internal bribeMod;
    address mockTarget;
    uint256 defaultValue = 1;
    address alice = vm.addr(1);
    address bob = vm.addr(2);

    function setUp() public {
        bribeMod = new BribeMod();
        mockTarget = address(new MockTarget());
    }

    function testNonce() public {
        assertEq(bribeMod.nonce(), 0);

        vm.store(address(bribeMod), bytes32(uint256(keccak256("EtherDeckMk2.Nonce")) - 1), bytes32(uint256(1)));

        assertEq(bribeMod.nonce(), 1);
    }

    function testBribeBuilder() public {
        setRunner(alice);
        vm.deal(alice, defaultValue);
        vm.deal(address(bribeMod), defaultValue);

        bytes memory payload = hex"aabbccdd";

        vm.expectCall(mockTarget, defaultValue, payload);

        vm.coinbase(bob);

        vm.prank(alice);
        bribeMod.bribeBuilder{ value: defaultValue }(mockTarget, payload, defaultValue);

        assertEq(alice.balance, 0);
        assertEq(bob.balance, defaultValue);
        assertEq(address(bribeMod).balance, 0);
        assertEq(mockTarget.balance, defaultValue);
    }

    function testBribeBuilderNotRunner() public {
        setRunner(alice);
        vm.deal(alice, defaultValue);
        vm.deal(address(bribeMod), defaultValue);

        bytes memory payload = hex"aabbccdd";

        vm.expectRevert();

        vm.prank(bob);
        bribeMod.bribeBuilder{ value: defaultValue }(mockTarget, payload, defaultValue);
    }

    function testBribeBuilderInsufficientBalance() public {
        setRunner(alice);
        vm.deal(alice, defaultValue);

        bytes memory payload = hex"aabbccdd";

        vm.expectRevert();

        bribeMod.bribeBuilder{ value: defaultValue }(mockTarget, payload, defaultValue);
    }

    function testBribeBuilderTargetReverts() public {
        setRunner(alice);
        vm.deal(alice, defaultValue);
        vm.deal(address(bribeMod), defaultValue);

        vm.etch(mockTarget, hex"5f5ffd");

        bytes memory payload = hex"aabbccdd";

        vm.expectRevert();

        bribeMod.bribeBuilder{ value: defaultValue }(mockTarget, payload, defaultValue);
    }

    function testBribeCaller() public {
        setRunner(alice);
        vm.deal(alice, defaultValue);
        vm.deal(address(bribeMod), defaultValue);

        bytes memory payload = hex"aabbccdd";
        bytes32 sighash =
            keccak256(abi.encodePacked(payload, uint256(uint160(mockTarget)), defaultValue, defaultValue, bribeMod.nonce()));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, sighash);
        bytes memory sigdata = abi.encode(sighash, v, r, s);

        vm.expectCall(mockTarget, defaultValue, payload);

        vm.prank(alice);
        bribeMod.bribeCaller{ value: defaultValue }(mockTarget, payload, sigdata, defaultValue);

        assertEq(alice.balance, defaultValue);
        assertEq(bob.balance, 0);
        assertEq(address(bribeMod).balance, 0);
        assertEq(mockTarget.balance, defaultValue);
    }

    function testBribeCallerNotRunner() public {
        setRunner(alice);
        vm.deal(bob, defaultValue);
        vm.deal(address(bribeMod), defaultValue);

        bytes memory payload = hex"aabbccdd";
        bytes32 sighash =
            keccak256(abi.encodePacked(payload, uint256(uint160(mockTarget)), defaultValue, defaultValue, bribeMod.nonce()));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, sighash);
        bytes memory sigdata = abi.encode(sighash, v, r, s);

        vm.expectCall(mockTarget, defaultValue, payload);

        vm.deal(bob, defaultValue);
        vm.startPrank(bob);
        bribeMod.bribeCaller{ value: defaultValue }(mockTarget, payload, sigdata, defaultValue);
        vm.stopPrank();

        assertEq(alice.balance, 0);
        assertEq(bob.balance, defaultValue);
        assertEq(address(bribeMod).balance, 0);
        assertEq(mockTarget.balance, defaultValue);
    }

    function testBribeCallerInvalidSigdata() public {
        setRunner(alice);
        vm.deal(alice, defaultValue);
        vm.deal(address(bribeMod), defaultValue);

        bytes memory payload = hex"aabbccdd";
        bytes memory sigdata = abi.encode(1, 2, 3);

        vm.expectRevert();

        bribeMod.bribeCaller{ value: defaultValue }(mockTarget, payload, sigdata, defaultValue);
    }

    function testBribeCallerInsufficientBalance() public {
        setRunner(alice);
        vm.deal(alice, defaultValue);

        bytes memory payload = hex"aabbccdd";
        bytes32 sighash =
            keccak256(abi.encodePacked(payload, uint256(uint160(mockTarget)), defaultValue, defaultValue, bribeMod.nonce()));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, sighash);
        bytes memory sigdata = abi.encode(sighash, v, r, s);

        vm.expectRevert();

        bribeMod.bribeCaller{ value: defaultValue }(mockTarget, payload, sigdata, defaultValue);
    }

    function testFuzzNonce(uint256 nonce) public {
        assertEq(bribeMod.nonce(), 0);

        vm.store(address(bribeMod), bytes32(uint256(keccak256("EtherDeckMk2.Nonce")) - 1), bytes32(nonce));

        assertEq(bribeMod.nonce(), nonce);
    }

    function setRunner(address runner) internal {
        vm.store(address(bribeMod), bytes32(uint256(1)), bytes32(uint256(uint160(runner))));
    }
}
