// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import { Test } from "../lib/forge-std/src/Test.sol";

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

        MockTarget(payable(mockTarget)).setThrows(true);

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

    function testRunBatchNoValue() public asPaidActor(alice, 0) {
        address[] memory targets = new address[](2);
        targets[0] = mockTarget;
        targets[1] = address(0xffff);
        vm.etch(address(0xffff), mockTarget.code);

        uint256[] memory values = new uint256[](2);
        values[0] = 0;
        values[1] = 0;

        bytes[] memory payloads = new bytes[](2);
        payloads[0] = hex"aabbccdd";
        payloads[1] = hex"eeffaabb";

        vm.expectCall(targets[0], values[0], payloads[0]);
        vm.expectCall(targets[1], values[1], payloads[1]);

        deck.runBatch(targets, values, payloads);
    }

    function testRunBatchEmptyCalldata() public asPaidActor(alice, defaultValue * 2) {
        address[] memory targets = new address[](2);
        targets[0] = mockTarget;
        targets[1] = address(0xffff);
        vm.etch(address(0xffff), mockTarget.code);

        uint256[] memory values = new uint256[](2);
        values[0] = defaultValue;
        values[1] = defaultValue;

        bytes[] memory payloads = new bytes[](2);
        payloads[0] = hex"";
        payloads[1] = hex"";

        vm.expectCall(targets[0], values[0], payloads[0]);
        vm.expectCall(targets[1], values[1], payloads[1]);

        deck.runBatch{ value: defaultValue * 2 }(targets, values, payloads);
    }

    function testRunBatchNotOwner() public {
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

        vm.expectRevert();

        vm.deal(bob, defaultValue * 2);
        vm.prank(bob);
        deck.runBatch{ value: defaultValue * 2 }(targets, values, payloads);
    }

    function testRunBatchCallReverts() public asPaidActor(alice, defaultValue * 2) {
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

        MockTarget(payable(targets[1])).setThrows(true);

        vm.expectRevert();

        deck.runBatch{ value: defaultValue * 2 }(targets, values, payloads);
    }

    function testSetDispatch() public asPaidActor(alice, 0) {
        assertEq(deck.dispatch(defaultSelector), address(0));

        deck.setDispatch(defaultSelector, mockTarget);

        assertEq(deck.dispatch(defaultSelector), mockTarget);
    }

    function testDispatch() public asPaidActor(alice, 0) {
        deck.setDispatch(MockMod.runMod.selector, mockMod);

        vm.expectEmit(true, true, true, true);
        emit MockMod.RunMod();

        MockMod(payable(deck)).runMod();
    }

    function testDispatchReverts() public asPaidActor(alice, 0) {
        deck.setDispatch(MockMod.setThrows.selector, mockMod);

        MockMod(payable(deck)).setThrows(true);

        deck.setDispatch(MockMod.runMod.selector, mockMod);

        vm.expectRevert();

        MockMod(payable(deck)).runMod();
    }

    function testEmptyDispatch() public {
        (bool succ, bytes memory retdata) = address(deck).call(abi.encode(defaultSelector));
        (bytes4 expected) = abi.decode(retdata, (bytes4));

        assertEq(expected, defaultSelector);
        assertTrue(succ);
    }

    function testFuzzRun(
        address actor,
        bytes32 salt,
        uint256 value,
        bytes memory payload,
        bool throws
    ) public asPaidActor(actor, value) {
        address target = address(new MockTarget{ salt: salt }());

        MockTarget(payable(target)).setThrows(throws);

        if (throws) {
            vm.expectRevert();
        } else {
            vm.expectCall(target, value, payload);
        }

        deck.run{ value: value }(target, payload);
    }

    function testFuzzRunBatch(
        address actor,
        bytes32 salt,
        uint256[16] memory staticValues,
        bytes[16] memory staticPayloads,
        uint256 length,
        bool throws
    ) public asPaidActor(actor, 0) {
        uint256 value;

        length = bound(length, 0, 16);

        address[] memory targets = new address[](length);
        uint256[] memory values = new uint256[](length);
        bytes[] memory payloads = new bytes[](length);

        for (uint256 i; i < length; i++) {
            targets[i] = address(new MockTarget{ salt: salt }());
            values[i] = bound(staticValues[i], 0, type(uint96).max);
            payloads[i] = staticPayloads[i];

            MockTarget(payable(targets[i])).setThrows(throws);

            value += values[i];
            salt = keccak256(abi.encode(salt));

            vm.deal(actor, actor.balance + values[i]);
            vm.etch(targets[i], mockTarget.code);
            if (!throws) vm.expectCall(targets[i], values[i], payloads[i]);
        }

        if (throws && length != 0) {
            vm.expectRevert();
        }

        deck.runBatch{ value: value }(targets, values, payloads);
    }

    function testFuzzSetDispatch(
        bool runnerIsActor,
        address actor,
        address runner,
        bytes4 selector,
        address target
    ) public asPaidActor(runner, 0) {
        actor = runnerIsActor ? runner : actor;

        assertEq(deck.dispatch(selector), address(0));

        if (runner == actor) {
            vm.expectEmit(true, true, true, true);
            emit EtherDeckMk2.DispatchSet(selector, target);
        } else {
            vm.expectRevert();
        }

        vm.startPrank(actor);
        deck.setDispatch(selector, target);
        vm.stopPrank();

        if (runner == actor) {
            assertEq(deck.dispatch(selector), target);
        } else {
            assertEq(deck.dispatch(selector), address(0));
        }
    }

    function testFuzzDispatch(
        bool shouldSet,
        bytes4 selector,
        bytes32 salt,
        bool throws
    ) public asPaidActor(alice, 0) {
        vm.assume(selector != MockMod.setThrows.selector && selector != MockMod.runMod.selector);

        address mod = address(new MockMod{ salt: salt }());

        deck.setDispatch(MockMod.setThrows.selector, mod);
        MockMod(payable(deck)).setThrows(throws);
        deck.setDispatch(MockMod.setThrows.selector, address(0));

        bytes memory payload = abi.encode(selector);

        if (shouldSet) {
            deck.setDispatch(selector, mod);
            if (!throws) {
                vm.expectEmit(true, true, true, true);
                emit MockMod.Fallback();
            }
        }

        (bool succ, bytes memory retdata) = address(deck).call(payload);

        if (shouldSet && !throws) {
            assertTrue(succ);
        } else if (shouldSet && throws) {
            assertFalse(succ);
        } else {
            (bytes4 expected) = abi.decode(retdata, (bytes4));
            assertEq(expected, selector);
        }
    }
}
