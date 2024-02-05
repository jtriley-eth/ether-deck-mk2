// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

import { Test } from "../../lib/forge-std/src/Test.sol";

import { MassRevokeMod } from "../../src/mods/MassRevokeMod.sol";
import { DifferentialMassRevokeMod } from "./implementations/DifferentialMassRevokeMod.sol";

import { MockERC20 } from "../mock/MockERC20.sol";
import { MockERC721 } from "../mock/MockERC721.sol";
import { MockERC1155 } from "../mock/MockERC1155.sol";
import { MockERC6909 } from "../mock/MockERC6909.sol";

contract DifferentialMassRevokeModTest is Test {
    MassRevokeMod internal fastRevokeMod;
    DifferentialMassRevokeMod internal slowRevokeMod;

    function setUp() public {
        fastRevokeMod = new MassRevokeMod();
        slowRevokeMod = new DifferentialMassRevokeMod();
    }

    function testFuzzDiffRevokeERC20Approval(
        bool runnerIsActor,
        address runner,
        address actor,
        bytes32 salt,
        address[] calldata spenders,
        bool lengthMismatch
    ) public {
        runner = runnerIsActor ? actor : runner;

        setRunner(runner);

        address[] memory tokens = new address[](lengthMismatch ? spenders.length + 1 : spenders.length);

        for (uint256 i; i < spenders.length; i++) {
            tokens[i] = address(new MockERC20{ salt: salt }());
            salt = keccak256(abi.encode(salt));

            vm.prank(address(fastRevokeMod));
            MockERC20(tokens[i]).approve(spenders[i], 1);

            assertEq(MockERC20(tokens[i]).allowance(address(fastRevokeMod), spenders[i]), 1);

            vm.prank(address(slowRevokeMod));
            MockERC20(tokens[i]).approve(spenders[i], 1);

            assertEq(MockERC20(tokens[i]).allowance(address(slowRevokeMod), spenders[i]), 1);
        }

        vm.startPrank(actor);

        if (runner != actor || lengthMismatch) {
            vm.expectRevert();
            fastRevokeMod.revokeERC20Approval(tokens, spenders);

            vm.expectRevert();
            slowRevokeMod.revokeERC20Approval(tokens, spenders);
        } else {
            fastRevokeMod.revokeERC20Approval(tokens, spenders);
            slowRevokeMod.revokeERC20Approval(tokens, spenders);

            for (uint256 i; i < tokens.length; i++) {
                assertEq(MockERC20(tokens[i]).allowance(address(fastRevokeMod), spenders[i]), 0);
                assertEq(MockERC20(tokens[i]).allowance(address(slowRevokeMod), spenders[i]), 0);
            }
        }

        vm.stopPrank();
    }

    function testFuzzDiffRevokeERC721Approval(
        bool runnerIsActor,
        address runner,
        address actor,
        bytes32 salt,
        uint256[] calldata ids,
        bool lengthMismatch
    ) public {
        runner = runnerIsActor ? actor : runner;

        setRunner(runner);

        address[] memory tokens0 = new address[](lengthMismatch ? ids.length + 1 : ids.length);
        address[] memory tokens1 = new address[](lengthMismatch ? ids.length + 1 : ids.length);

        for (uint256 i; i < ids.length; i++) {
            address spender = address(bytes20(keccak256(abi.encode(ids[i]))));
            tokens0[i] = address(new MockERC721{ salt: salt }());
            salt = keccak256(abi.encode(salt));
            tokens1[i] = address(new MockERC721{ salt: salt }());
            salt = keccak256(abi.encode(salt));

            MockERC721(tokens0[i]).mint(address(fastRevokeMod), ids[i]);
            MockERC721(tokens1[i]).mint(address(slowRevokeMod), ids[i]);

            vm.prank(address(fastRevokeMod));
            MockERC721(tokens0[i]).approve(spender, ids[i]);

            assertEq(MockERC721(tokens0[i]).getApproved(ids[i]), spender);

            vm.prank(address(slowRevokeMod));
            MockERC721(tokens1[i]).approve(spender, ids[i]);

            assertEq(MockERC721(tokens1[i]).getApproved(ids[i]), spender);
        }

        vm.startPrank(actor);

        if (runner != actor || lengthMismatch) {
            vm.expectRevert();
            fastRevokeMod.revokeERC721Approval(tokens0, ids);

            vm.expectRevert();
            slowRevokeMod.revokeERC721Approval(tokens1, ids);
        } else {
            fastRevokeMod.revokeERC721Approval(tokens0, ids);
            slowRevokeMod.revokeERC721Approval(tokens1, ids);

            for (uint256 i; i < tokens0.length; i++) {
                assertEq(MockERC721(tokens0[i]).getApproved(ids[i]), address(0));
                assertEq(MockERC721(tokens1[i]).getApproved(ids[i]), address(0));
            }
        }

        vm.stopPrank();
    }

    function testFuzzDiffRevokeERC6909Approval(
        bool runnerIsActor,
        address runner,
        address actor,
        bytes32 salt,
        uint256[] calldata ids,
        bool lengthMismatch
    ) public {
        runner = runnerIsActor ? actor : runner;

        setRunner(runner);

        address[] memory tokens = new address[](lengthMismatch ? ids.length + 1 : ids.length);
        address[] memory operators = new address[](ids.length);

        for (uint256 i; i < ids.length; i++) {
            operators[i] = address(bytes20(keccak256(abi.encode(i))));
            tokens[i] = address(new MockERC6909{ salt: salt }());
            salt = keccak256(abi.encode(salt));

            vm.prank(address(fastRevokeMod));
            MockERC6909(tokens[i]).approve(operators[i], ids[i], 1);

            assertEq(MockERC6909(tokens[i]).allowance(address(fastRevokeMod), operators[i], ids[i]), 1);

            vm.prank(address(slowRevokeMod));
            MockERC6909(tokens[i]).approve(operators[i], ids[i], 1);

            assertEq(MockERC6909(tokens[i]).allowance(address(slowRevokeMod), operators[i], ids[i]), 1);
        }

        vm.startPrank(actor);

        if (runner != actor || lengthMismatch) {
            vm.expectRevert();
            fastRevokeMod.revokeERC6909Approval(tokens, ids, operators);

            vm.expectRevert();
            slowRevokeMod.revokeERC6909Approval(tokens, ids, operators);
        } else {
            fastRevokeMod.revokeERC6909Approval(tokens, ids, operators);
            slowRevokeMod.revokeERC6909Approval(tokens, ids, operators);

            for (uint256 i; i < tokens.length; i++) {
                assertEq(MockERC6909(tokens[i]).allowance(address(fastRevokeMod), operators[i], ids[i]), 0);
                assertEq(MockERC6909(tokens[i]).allowance(address(slowRevokeMod), operators[i], ids[i]), 0);
            }
        }

        vm.stopPrank();
    }

    function testFuzzDiffApprovalForAll(
        bool runnerIsActor,
        address runner,
        address actor,
        bytes32 salt,
        address[] calldata operators,
        bool lengthMismatch
    ) public {
        runner = runnerIsActor ? actor : runner;

        setRunner(runner);

        address[] memory tokens0 = new address[](lengthMismatch ? operators.length + 1 : operators.length);
        address[] memory tokens1 = new address[](lengthMismatch ? operators.length + 1 : operators.length);

        for (uint256 i; i < operators.length; i++) {
            bool isERC721 = uint256(salt) % 2 == 0;
            tokens0[i] = isERC721 ? address(new MockERC721{ salt: salt }()) : address(new MockERC1155{ salt: salt }());
            salt = keccak256(abi.encode(salt));
            tokens1[i] = isERC721 ? address(new MockERC721{ salt: salt }()) : address(new MockERC1155{ salt: salt }());
            salt = keccak256(abi.encode(salt));

            if (isERC721) {
                MockERC721(tokens0[i]).mint(address(fastRevokeMod), i);
                MockERC721(tokens1[i]).mint(address(slowRevokeMod), i);
            }

            vm.prank(address(fastRevokeMod));
            MockERC721(tokens0[i]).setApprovalForAll(operators[i], true);

            assertTrue(MockERC721(tokens0[i]).isApprovedForAll(address(fastRevokeMod), operators[i]));

            vm.prank(address(slowRevokeMod));
            MockERC721(tokens1[i]).setApprovalForAll(operators[i], true);

            assertTrue(MockERC721(tokens1[i]).isApprovedForAll(address(slowRevokeMod), operators[i]));
        }

        vm.startPrank(actor);

        if (runner != actor || lengthMismatch) {
            vm.expectRevert();
            fastRevokeMod.revokeApprovalForAll(tokens0, operators);

            vm.expectRevert();
            slowRevokeMod.revokeApprovalForAll(tokens1, operators);
        } else {
            fastRevokeMod.revokeApprovalForAll(tokens0, operators);
            slowRevokeMod.revokeApprovalForAll(tokens1, operators);

            for (uint256 i; i < tokens0.length; i++) {
                assertFalse(MockERC1155(tokens0[i]).isApprovedForAll(address(fastRevokeMod), operators[i]));
                assertFalse(MockERC1155(tokens1[i]).isApprovedForAll(address(slowRevokeMod), operators[i]));
            }
        }

        vm.stopPrank();
    }

    function testFuzzDiffRevokeOperator(
        bool runnerIsActor,
        address runner,
        address actor,
        bytes32 salt,
        address[] calldata operators,
        bool lengthMismatch
    ) public {
        runner = runnerIsActor ? actor : runner;

        setRunner(runner);

        address[] memory tokens = new address[](lengthMismatch ? operators.length + 1 : operators.length);

        for (uint256 i; i < operators.length; i++) {
            tokens[i] = address(new MockERC6909{ salt: salt }());
            salt = keccak256(abi.encode(salt));

            vm.prank(address(fastRevokeMod));
            MockERC6909(tokens[i]).setOperator(operators[i], true);

            assertTrue(MockERC6909(tokens[i]).isOperator(address(fastRevokeMod), operators[i]));

            vm.prank(address(slowRevokeMod));
            MockERC6909(tokens[i]).setOperator(operators[i], true);

            assertTrue(MockERC6909(tokens[i]).isOperator(address(slowRevokeMod), operators[i]));
        }

        vm.startPrank(actor);

        if (runner != actor || lengthMismatch) {
            vm.expectRevert();
            fastRevokeMod.revokeOperator(tokens, operators);

            vm.expectRevert();
            slowRevokeMod.revokeOperator(tokens, operators);
        } else {
            fastRevokeMod.revokeOperator(tokens, operators);
            slowRevokeMod.revokeOperator(tokens, operators);

            for (uint256 i; i < tokens.length; i++) {
                assertFalse(MockERC6909(tokens[i]).isOperator(address(fastRevokeMod), operators[i]));
                assertFalse(MockERC6909(tokens[i]).isOperator(address(slowRevokeMod), operators[i]));
            }
        }

        vm.stopPrank();
    }

    function setRunner(address runner) internal {
        vm.store(address(fastRevokeMod), bytes32(uint256(1)), bytes32(uint256(uint160(runner))));
        vm.store(address(slowRevokeMod), bytes32(uint256(1)), bytes32(uint256(uint160(runner))));
    }
}
