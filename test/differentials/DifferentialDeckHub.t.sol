// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

import { DeckHub } from "../../src/DeckHub.sol";
import { DifferentialDeckHub } from "./implementations/DifferentialDeckHub.sol";

import { EtherDeckMk2 } from "../../src/EtherDeckMk2.sol";

import { Test } from "../../lib/forge-std/src/Test.sol";

contract DifferentialDeckHubTest is Test {
    DeckHub internal fastHub;
    DifferentialDeckHub internal slowHub;

    function setUp() public {
        fastHub = new DeckHub();
        slowHub = new DifferentialDeckHub();
    }

    function testFuzzDiffDeploy(
        address actor,
        address runner,
        bytes32 salt
    ) public {
        vm.expectEmit(true, true, true, true, address(fastHub));
        emit DeckHub.Deployed(actor, compute(address(fastHub), runner, salt));
        vm.prank(actor);
        address fastDeck = fastHub.deploy(runner, salt);

        vm.expectEmit(true, true, true, true, address(slowHub));
        emit DifferentialDeckHub.Deployed(actor, compute(address(slowHub), runner, salt));
        vm.prank(actor);
        address slowDeck = slowHub.deploy(runner, salt);

        assertEq(EtherDeckMk2(payable(fastDeck)).runner(), runner);
        assertEq(EtherDeckMk2(payable(slowDeck)).runner(), runner);
        assertEq(fastDeck.codehash, slowDeck.codehash);
    }

    function compute(address hub, address runner, bytes32 salt) internal pure returns (address) {
        return address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            hub,
                            salt,
                            keccak256(abi.encodePacked(type(EtherDeckMk2).creationCode, uint256(uint160(runner))))
                        )
                    )
                )
            )
        );
    }
}
