// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

import { Test } from "../lib/forge-std/src/Test.sol";

import { ReceiverMod } from "../src/mods/ReceiverMod.sol";

contract ReceiverModTest is Test {
    ReceiverMod internal receiverMod;

    address internal alice = vm.addr(1);
    address internal bob = vm.addr(2);

    bytes4 defaulSelector = bytes4(0xaabbccdd);

    function setUp() public {
        receiverMod = new ReceiverMod();
    }

    function testFallback() public {
        (bool success, bytes memory data) = address(receiverMod).call(abi.encodeWithSelector(defaulSelector));

        (bytes4 retSelector) = abi.decode(data, (bytes4));

        assertTrue(success);
        assertEq(retSelector, defaulSelector);
    }

    function testFuzzFallback(bytes4 selector) public {
        (bool success, bytes memory data) = address(receiverMod).call(abi.encodeWithSelector(selector));

        (bytes4 retSelector) = abi.decode(data, (bytes4));

        assertTrue(success);
        assertEq(retSelector, selector);
    }
}
