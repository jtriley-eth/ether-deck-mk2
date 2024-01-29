// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import { Test, console } from "../lib/forge-std/src/Test.sol";

import { EtherDeckMk2 } from "../src/EtherDeckMk2.sol";
import { MockTarget } from "./mock/MockTarget.sol";
import { MockMod } from "./mock/MockMod.sol";

contract EtherDeckMk2Test is Test {
    EtherDeckMk2 deck;
    address mockTarget;
    address mockMod;
    uint256 defaultValue = 1;
    bytes4 defaultSelector = 0xaabbccdd;
    address alice = vm.addr(1);
    address bob = vm.addr(2);

    modifier asPaidActor(address actor, uint256 value) {
        vm.deal(actor, value);
        vm.store(address(deck), bytes32(uint256(1)), bytes32(uint256(uint160(actor))));
        vm.startPrank(actor);
        _;
        vm.stopPrank();
    }

    function setUp() public {
        deck = new EtherDeckMk2();
        mockTarget = address(new MockTarget());
        mockMod = address(new MockMod());
    }

    function testRun() public asPaidActor(alice, defaultValue) {
        bytes memory payload = hex"aabbccdd";

        vm.expectCall(mockTarget, defaultValue, payload);

        deck.run{ value: defaultValue }(mockTarget, payload);
    }

    function testRunNoValue() public asPaidActor(alice, 0) {
        bytes memory payload = hex"aabbccdd";

        vm.expectCall(mockTarget, 0, payload);

        deck.run(mockTarget, payload);
    }

    function testRunEmptyCalldata() public asPaidActor(alice, defaultValue) {
        bytes memory payload = hex"";

        vm.expectCall(mockTarget, defaultValue, payload);

        deck.run{ value: defaultValue }(mockTarget, payload);
    }

    function testRunNotOwner() public {
        bytes memory payload = hex"aabbccdd";

        vm.expectRevert();

        vm.deal(bob, defaultValue);
        vm.prank(bob);
        deck.run{ value: defaultValue }(mockTarget, payload);
    }

    function testRunCallReverts() public asPaidActor(alice, defaultValue) {
        bytes memory payload = hex"aabbccdd";

        vm.etch(mockTarget, hex"5f5ffd");

        vm.expectRevert();

        deck.run(mockTarget, payload);
    }

    function testRunBatch() public asPaidActor(alice, defaultValue * 2) {
        address[] memory targets = new address[](2);
        targets[0] = mockTarget;
        targets[1] = address(0xffff);
        vm.etch(address(0xffff), mockTarget.code);

        uint256[] memory values = new uint256[](2);
        values[0] = defaultValue;
        values[1] = defaultValue;

        bytes[] memory payloads = new bytes[](2);
        payloads[0] = hex"aabbccdd";
        payloads[1] = hex"eeffaabb";

        vm.expectCall(targets[0], values[0], payloads[0]);
        vm.expectCall(targets[1], values[1], payloads[1]);

        deck.runBatch{ value: defaultValue * 2 }(targets, values, payloads);
    }

    function testRunFrom() public asPaidActor(alice, defaultValue * 2) {
        assertEq(alice.balance, defaultValue * 2);
        assertEq(address(deck).balance, 0);
        assertEq(mockTarget.balance, 0);

        payable(deck).transfer(defaultValue);

        assertEq(alice.balance, defaultValue);
        assertEq(address(deck).balance, defaultValue);
        assertEq(mockTarget.balance, 0);

        bytes memory payload = hex"aabbccdd";
        bytes32 sighash =
            keccak256(abi.encodePacked(payload, uint256(uint160(mockTarget)), defaultValue, defaultValue, deck.nonce()));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, sighash);
        bytes memory sigdata = abi.encode(sighash, v, r, s);

        vm.expectCall(mockTarget, defaultValue, payload);

        deck.runFrom{ value: defaultValue }(mockTarget, payload, sigdata, defaultValue);

        assertEq(alice.balance, defaultValue);
        assertEq(address(deck).balance, 0);
        assertEq(mockTarget.balance, defaultValue);
    }

    function testRunFromNotRunner() public asPaidActor(alice, defaultValue) {
        vm.deal(bob, defaultValue);
        assertEq(alice.balance, defaultValue);
        assertEq(address(deck).balance, 0);
        assertEq(mockTarget.balance, 0);
        assertEq(bob.balance, defaultValue);

        payable(deck).transfer(defaultValue);

        assertEq(alice.balance, 0);
        assertEq(address(deck).balance, defaultValue);
        assertEq(mockTarget.balance, 0);
        assertEq(bob.balance, defaultValue);

        bytes memory payload = hex"aabbccdd";
        bytes32 sighash =
            keccak256(abi.encodePacked(payload, uint256(uint160(mockTarget)), defaultValue, defaultValue, deck.nonce()));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, sighash);
        bytes memory sigdata = abi.encode(sighash, v, r, s);

        vm.expectCall(mockTarget, defaultValue, payload);

        vm.deal(bob, defaultValue);
        vm.startPrank(bob);
        deck.runFrom{ value: defaultValue }(mockTarget, payload, sigdata, defaultValue);
        vm.stopPrank();

        assertEq(alice.balance, 0);
        assertEq(address(deck).balance, 0);
        assertEq(mockTarget.balance, defaultValue);
        assertEq(bob.balance, defaultValue);
    }

    function testRunFromInvalidSigdata() public asPaidActor(alice, defaultValue * 2) {
        assertEq(alice.balance, defaultValue * 2);
        assertEq(address(deck).balance, 0);
        assertEq(mockTarget.balance, 0);

        payable(deck).transfer(defaultValue);

        assertEq(alice.balance, defaultValue);
        assertEq(address(deck).balance, defaultValue);
        assertEq(mockTarget.balance, 0);

        bytes memory payload = hex"aabbccdd";
        bytes memory sigdata = abi.encode(1, 2, 3);

        vm.expectRevert();

        deck.runFrom{ value: defaultValue }(mockTarget, payload, sigdata, defaultValue);
    }

    function testRunFromInsufficientBalance() public asPaidActor(alice, defaultValue) {
        assertEq(alice.balance, defaultValue);
        assertEq(address(deck).balance, 0);
        assertEq(mockTarget.balance, 0);

        bytes memory payload = hex"aabbccdd";
        bytes32 sighash =
            keccak256(abi.encodePacked(payload, uint256(uint160(mockTarget)), defaultValue, defaultValue, deck.nonce()));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, sighash);
        bytes memory sigdata = abi.encode(sighash, v, r, s);

        vm.expectRevert();

        deck.runFrom{ value: defaultValue }(mockTarget, payload, sigdata, defaultValue);
    }

    function testSetDispatch() public {
        assertEq(deck.dispatch(defaultSelector), address(0));

        deck.setDispatch(defaultSelector, mockTarget);

        assertEq(deck.dispatch(defaultSelector), mockTarget);
    }

    function testDispatch() public {
        deck.setDispatch(MockMod.runMod.selector, mockMod);

        vm.expectCall(mockMod, 0, abi.encode(MockMod.runMod.selector));

        vm.expectEmit(true, true, true, true);
        emit MockMod.RunMod();

        (bool succ,) = address(deck).call(abi.encode(MockMod.runMod.selector));

        assertTrue(succ);
    }

    function testEmptyDispatch() public {
        (bool succ, bytes memory retdata) = address(deck).call(abi.encode(defaultSelector));
        (bytes4 expected) = abi.decode(retdata, (bytes4));

        assertEq(expected, defaultSelector);
        assertTrue(succ);
    }

    function testFuzzRun(
        address actor,
        address target,
        uint256 value,
        bytes memory payload
    ) public asPaidActor(actor, value) {
        target = boundAddy(target);

        vm.etch(target, mockTarget.code);

        vm.expectCall(target, value, payload);

        deck.run{ value: value }(target, payload);
    }

    function testFuzzRunBatch(
        address actor,
        address[16] memory staticTargets,
        uint256[16] memory staticValues,
        bytes[16] memory staticPayloads,
        uint256 length
    ) public asPaidActor(actor, 0) {
        uint256 value;

        length = bound(length, 0, 16);

        address[] memory targets = new address[](length);
        uint256[] memory values = new uint256[](length);
        bytes[] memory payloads = new bytes[](length);

        for (uint256 i; i < length; i++) {
            targets[i] = boundAddy(staticTargets[i]);
            values[i] = bound(staticValues[i], 0, type(uint96).max);
            payloads[i] = staticPayloads[i];

            value += values[i];

            vm.deal(actor, actor.balance + values[i]);
            vm.etch(targets[i], mockTarget.code);
            vm.expectCall(targets[i], values[i], payloads[i]);
        }

        deck.runBatch{ value: value }(targets, values, payloads);
    }

    function testFuzzSetDispatch(bytes4 selector, address target) public {
        assertEq(deck.dispatch(selector), address(0));

        deck.setDispatch(selector, target);

        assertEq(deck.dispatch(selector), target);
    }

    function testFuzzDispatch(bool shouldSet, bytes4 selector, address target) public {
        target = boundAddy(target);
        vm.etch(target, mockTarget.code);

        bytes memory payload = abi.encode(selector);

        if (shouldSet) deck.setDispatch(selector, target);

        (bool succ, bytes memory retdata) = address(deck).call(payload);

        assertTrue(succ);

        if (shouldSet) {
            assertEq(keccak256(retdata), keccak256(payload));
        } else {
            (bytes4 expected) = abi.decode(retdata, (bytes4));
            assertEq(expected, selector);
        }
    }

    function boundAddy(address addy) internal view returns (address) {
        if (
            uint160(addy) < 256 || addy == address(deck) || addy == 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
                || addy == 0x000000000000000000636F6e736F6c652e6c6f67 || addy == 0x4e59b44847b379578588920cA78FbF26c0B4956C
        ) addy = address(uint160(addy) + 256);
        return addy;
    }
}
