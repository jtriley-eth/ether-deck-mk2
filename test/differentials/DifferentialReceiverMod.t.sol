// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

import { Test } from "../../lib/forge-std/src/Test.sol";

import { ReceiverMod } from "../../src/mods/ReceiverMod.sol";
import { DifferentialReceiverMod } from "./implementations/DifferentialReceiverMod.sol";

contract DifferentialReceiverModTest is Test {
    ReceiverMod internal fastReceiverMod;
    DifferentialReceiverMod internal slowReceiverMod;

    function setUp() public {
        fastReceiverMod = new ReceiverMod();
        slowReceiverMod = new DifferentialReceiverMod();
    }

    function testFuzzDiffFallback(bytes4 selector) public {
        (bool fastSucc, bytes memory fastData) = address(fastReceiverMod).call(abi.encodeWithSelector(selector));
        (bool slowSucc, bytes memory slowData) = address(slowReceiverMod).call(abi.encodeWithSelector(selector));

        (bytes4 fastRetSelector) = abi.decode(fastData, (bytes4));
        (bytes4 slowRetSelector) = abi.decode(slowData, (bytes4));

        assertTrue(fastSucc);
        assertTrue(slowSucc);
        assertEq(fastRetSelector, selector);
        assertEq(slowRetSelector, selector);
    }
}
