// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

import { Test } from "../../lib/forge-std/src/Test.sol";

import { TransferMod } from "../../src/mods/TransferMod.sol";
import { DifferentialTransferMod } from "./implementations/DifferentialTransferMod.sol";

import { MockERC20 } from "../mock/MockERC20.sol";
import { MockERC721 } from "../mock/MockERC721.sol";
import { MockERC1155 } from "../mock/MockERC1155.sol";
import { MockERC6909 } from "../mock/MockERC6909.sol";

contract DifferentialTransferModTest is Test {
    TransferMod internal fastTransferMod;
    DifferentialTransferMod internal slowTransferMod;

    function setUp() public {
        fastTransferMod = new TransferMod();
        slowTransferMod = new DifferentialTransferMod();
    }

    function testFuzzDiffTransferERC20(
        bool runnerIsActor,
        address runner,
        address actor,
        bytes32 salt,
        uint256[] memory amounts,
        bool lengthMismatch
    ) public {
        runner = runnerIsActor ? actor : runner;

        setRunner(runner);

        address[] memory tokens0 = new address[](lengthMismatch ? amounts.length + 1 : amounts.length);
        address[] memory tokens1 = new address[](lengthMismatch ? amounts.length + 1 : amounts.length);
        address[] memory receivers = new address[](amounts.length);

        for (uint256 i; i < amounts.length; i++) {
            tokens0[i] = address(new MockERC20{ salt: salt }());
            salt = keccak256(abi.encode(salt));
            tokens1[i] = address(new MockERC20{ salt: salt }());
            salt = keccak256(abi.encode(salt));
            receivers[i] = address(bytes20(keccak256(abi.encode(amounts[i]))));

            MockERC20(tokens0[i]).mint(address(fastTransferMod), amounts[i]);
            assertEq(MockERC20(tokens0[i]).balanceOf(address(fastTransferMod)), amounts[i]);
            assertEq(MockERC20(tokens0[i]).balanceOf(receivers[i]), 0);

            MockERC20(tokens1[i]).mint(address(slowTransferMod), amounts[i]);
            assertEq(MockERC20(tokens1[i]).balanceOf(address(slowTransferMod)), amounts[i]);
            assertEq(MockERC20(tokens1[i]).balanceOf(receivers[i]), 0);
        }

        vm.startPrank(actor);

        if (runner != actor || lengthMismatch) {
            vm.expectRevert();
            fastTransferMod.transferERC20(tokens0, receivers, amounts);

            vm.expectRevert();
            slowTransferMod.transferERC20(tokens1, receivers, amounts);
        } else {
            fastTransferMod.transferERC20(tokens0, receivers, amounts);
            slowTransferMod.transferERC20(tokens1, receivers, amounts);

            for (uint256 i; i < amounts.length; i++) {
                assertEq(MockERC20(tokens0[i]).balanceOf(address(fastTransferMod)), 0);
                assertEq(MockERC20(tokens0[i]).balanceOf(receivers[i]), amounts[i]);
                assertEq(MockERC20(tokens1[i]).balanceOf(address(slowTransferMod)), 0);
                assertEq(MockERC20(tokens1[i]).balanceOf(receivers[i]), amounts[i]);
            }
        }

        vm.stopPrank();
    }

    function testFuzzDiffTransferERC721(
        bool runnerIsActor,
        address runner,
        address actor,
        bytes32 salt,
        uint256[] memory ids,
        bool lengthMismatch
    ) public {
        runner = runnerIsActor ? actor : runner;

        setRunner(runner);

        address[] memory tokens0 = new address[](lengthMismatch ? ids.length + 1 : ids.length);
        address[] memory tokens1 = new address[](lengthMismatch ? ids.length + 1 : ids.length);
        address[] memory receivers = new address[](ids.length);

        for (uint256 i; i < ids.length; i++) {
            tokens0[i] = address(new MockERC721{ salt: salt }());
            salt = keccak256(abi.encode(salt));
            tokens1[i] = address(new MockERC721{ salt: salt }());
            salt = keccak256(abi.encode(salt));
            receivers[i] = address(bytes20(keccak256(abi.encode(ids[i]))));

            MockERC721(tokens0[i]).mint(address(fastTransferMod), ids[i]);
            assertEq(MockERC721(tokens0[i]).ownerOf(ids[i]), address(fastTransferMod));
            assertEq(MockERC721(tokens0[i]).balanceOf(address(fastTransferMod)), 1);
            assertEq(MockERC721(tokens0[i]).balanceOf(receivers[i]), 0);

            MockERC721(tokens1[i]).mint(address(slowTransferMod), ids[i]);
            assertEq(MockERC721(tokens1[i]).ownerOf(ids[i]), address(slowTransferMod));
            assertEq(MockERC721(tokens1[i]).balanceOf(address(slowTransferMod)), 1);
            assertEq(MockERC721(tokens1[i]).balanceOf(receivers[i]), 0);
        }

        vm.startPrank(actor);

        if (runner != actor || lengthMismatch) {
            vm.expectRevert();
            fastTransferMod.transferERC721(tokens0, receivers, ids);

            vm.expectRevert();
            slowTransferMod.transferERC721(tokens1, receivers, ids);
        } else {
            fastTransferMod.transferERC721(tokens0, receivers, ids);
            slowTransferMod.transferERC721(tokens1, receivers, ids);

            for (uint256 i; i < ids.length; i++) {
                assertEq(MockERC721(tokens0[i]).ownerOf(ids[i]), receivers[i]);
                assertEq(MockERC721(tokens0[i]).balanceOf(address(fastTransferMod)), 0);
                assertEq(MockERC721(tokens0[i]).balanceOf(receivers[i]), 1);
                assertEq(MockERC721(tokens1[i]).ownerOf(ids[i]), receivers[i]);
                assertEq(MockERC721(tokens1[i]).balanceOf(address(slowTransferMod)), 0);
                assertEq(MockERC721(tokens1[i]).balanceOf(receivers[i]), 1);
            }
        }

        vm.stopPrank();
    }

    function testFuzzDiffTransferERC1155(
        bool runnerIsActor,
        address runner,
        address actor,
        bytes32 salt,
        uint256[] memory amounts,
        bool lengthMismatch
    ) public {
        runner = runnerIsActor ? actor : runner;

        setRunner(runner);

        address[] memory tokens0 = new address[](lengthMismatch ? amounts.length + 1 : amounts.length);
        address[] memory tokens1 = new address[](lengthMismatch ? amounts.length + 1 : amounts.length);
        address[] memory receivers = new address[](amounts.length);
        uint256[] memory ids = new uint256[](amounts.length);

        for (uint256 i; i < amounts.length; i++) {
            tokens0[i] = address(new MockERC1155{ salt: salt }());
            salt = keccak256(abi.encode(salt));
            tokens1[i] = address(new MockERC1155{ salt: salt }());
            salt = keccak256(abi.encode(salt));
            receivers[i] = address(bytes20(keccak256(abi.encode(amounts[i]))));
            ids[i] = uint256(keccak256(abi.encode(receivers[i])));

            MockERC1155(tokens0[i]).mint(address(fastTransferMod), ids[i], amounts[i]);
            assertEq(MockERC1155(tokens0[i]).balanceOf(address(fastTransferMod), ids[i]), amounts[i]);
            assertEq(MockERC1155(tokens0[i]).balanceOf(receivers[i], ids[i]), 0);

            MockERC1155(tokens1[i]).mint(address(slowTransferMod), ids[i], amounts[i]);
            assertEq(MockERC1155(tokens1[i]).balanceOf(address(slowTransferMod), ids[i]), amounts[i]);
            assertEq(MockERC1155(tokens1[i]).balanceOf(receivers[i], ids[i]), 0);
        }

        vm.startPrank(actor);

        if (runner != actor || lengthMismatch) {
            vm.expectRevert();
            fastTransferMod.transferERC1155(tokens0, receivers, ids, amounts);

            vm.expectRevert();
            slowTransferMod.transferERC1155(tokens1, receivers, ids, amounts);
        } else {
            fastTransferMod.transferERC1155(tokens0, receivers, ids, amounts);
            slowTransferMod.transferERC1155(tokens1, receivers, ids, amounts);

            for (uint256 i; i < ids.length; i++) {
                assertEq(MockERC1155(tokens0[i]).balanceOf(address(fastTransferMod), ids[i]), 0);
                assertEq(MockERC1155(tokens0[i]).balanceOf(receivers[i], ids[i]), amounts[i]);
                assertEq(MockERC1155(tokens1[i]).balanceOf(address(slowTransferMod), ids[i]), 0);
                assertEq(MockERC1155(tokens1[i]).balanceOf(receivers[i], ids[i]), amounts[i]);
            }
        }

        vm.stopPrank();
    }

    function testFuzzDiffTransferERC6909(
        bool runnerIsActor,
        address runner,
        address actor,
        bytes32 salt,
        uint256[] memory amounts,
        bool lengthMismatch
    ) public {
        runner = runnerIsActor ? actor : runner;

        setRunner(runner);

        address[] memory tokens0 = new address[](lengthMismatch ? amounts.length + 1 : amounts.length);
        address[] memory tokens1 = new address[](lengthMismatch ? amounts.length + 1 : amounts.length);
        address[] memory receivers = new address[](amounts.length);
        uint256[] memory ids = new uint256[](amounts.length);

        for (uint256 i; i < ids.length; i++) {
            tokens0[i] = address(new MockERC6909{ salt: salt }());
            salt = keccak256(abi.encode(salt));
            tokens1[i] = address(new MockERC6909{ salt: salt }());
            salt = keccak256(abi.encode(salt));
            receivers[i] = address(bytes20(keccak256(abi.encode(ids[i]))));
            ids[i] = uint256(keccak256(abi.encode(receivers[i])));

            MockERC6909(tokens0[i]).mint(address(fastTransferMod), ids[i], amounts[i]);
            assertEq(MockERC6909(tokens0[i]).balanceOf(address(fastTransferMod), ids[i]), amounts[i]);
            assertEq(MockERC6909(tokens0[i]).balanceOf(receivers[i], ids[i]), 0);

            MockERC6909(tokens1[i]).mint(address(slowTransferMod), ids[i], amounts[i]);
            assertEq(MockERC6909(tokens1[i]).balanceOf(address(slowTransferMod), ids[i]), amounts[i]);
            assertEq(MockERC6909(tokens1[i]).balanceOf(receivers[i], ids[i]), 0);
        }

        vm.startPrank(actor);

        if (runner != actor || lengthMismatch) {
            vm.expectRevert();
            fastTransferMod.transferERC6909(tokens0, receivers, ids, amounts);

            vm.expectRevert();
            slowTransferMod.transferERC6909(tokens1, receivers, ids, amounts);
        } else {
            fastTransferMod.transferERC6909(tokens0, receivers, ids, amounts);
            slowTransferMod.transferERC6909(tokens1, receivers, ids, amounts);

            for (uint256 i; i < ids.length; i++) {
                assertEq(MockERC6909(tokens0[i]).balanceOf(address(fastTransferMod), ids[i]), 0);
                assertEq(MockERC6909(tokens0[i]).balanceOf(receivers[i], ids[i]), amounts[i]);
                assertEq(MockERC6909(tokens1[i]).balanceOf(address(slowTransferMod), ids[i]), 0);
                assertEq(MockERC6909(tokens1[i]).balanceOf(receivers[i], ids[i]), amounts[i]);
            }
        }

        vm.stopPrank();
    }

    function setRunner(address runner) internal {
        vm.store(address(fastTransferMod), bytes32(uint256(1)), bytes32(uint256(uint160(runner))));
        vm.store(address(slowTransferMod), bytes32(uint256(1)), bytes32(uint256(uint160(runner))));
    }
}
