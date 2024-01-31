// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import { Test } from "../lib/forge-std/src/Test.sol";

import { MassRevokeMod } from "../src/mods/MassRevokeMod.sol";
import { MockERC20 } from "./mock/MockERC20.sol";
import { MockERC721 } from "./mock/MockERC721.sol";
import { MockERC1155 } from "./mock/MockERC1155.sol";
import { MockERC6909 } from "./mock/MockERC6909.sol";

contract MassRevokeModTest is Test {
    MassRevokeMod internal revokeMod;
    MockERC20 internal erc20;
    MockERC721 internal erc721;
    MockERC1155 internal erc1155;
    MockERC6909 internal erc6909;

    address internal alice = vm.addr(1);
    address internal bob = vm.addr(2);
    address internal charlie = vm.addr(3);
    uint256 defaultId = 1;
    uint256 defaultAmount = 1;

    function setUp() public {
        revokeMod = new MassRevokeMod();
        erc20 = new MockERC20();
        erc721 = new MockERC721();
        erc1155 = new MockERC1155();
        erc6909 = new MockERC6909();
    }

    function testRevokeERC20ApprovalSingle() public {
        setRunner(alice);

        vm.prank(address(revokeMod));
        erc20.approve(bob, defaultAmount);

        assertEq(erc20.allowance(address(revokeMod), bob), defaultAmount);

        address[] memory tokens = new address[](1);
        tokens[0] = address(erc20);

        address[] memory spenders = new address[](1);
        spenders[0] = bob;

        vm.prank(alice);
        revokeMod.revokeERC20Approval(tokens, spenders);

        assertEq(erc20.allowance(address(revokeMod), bob), 0);
    }

    function testRevokeERC20ApprovalDouble() public {
        setRunner(alice);

        vm.prank(address(revokeMod));
        erc20.approve(bob, defaultAmount);

        vm.prank(address(revokeMod));
        erc20.approve(charlie, defaultAmount);

        assertEq(erc20.allowance(address(revokeMod), bob), defaultAmount);
        assertEq(erc20.allowance(address(revokeMod), charlie), defaultAmount);

        address[] memory tokens = new address[](2);
        tokens[0] = address(erc20);
        tokens[1] = address(erc20);

        address[] memory spenders = new address[](2);
        spenders[0] = bob;
        spenders[1] = charlie;

        vm.prank(alice);
        revokeMod.revokeERC20Approval(tokens, spenders);

        assertEq(erc20.allowance(address(revokeMod), bob), 0);
        assertEq(erc20.allowance(address(revokeMod), charlie), 0);
    }

    function testRevokeERC20EmptyList() public {
        setRunner(alice);

        vm.prank(alice);
        revokeMod.revokeERC20Approval(new address[](0), new address[](0));
    }

    function testRevokeERC20NotRunner() public {
        setRunner(alice);

        vm.expectRevert();

        vm.prank(bob);
        revokeMod.revokeERC20Approval(new address[](0), new address[](0));
    }

    function testRevokeERC20LengthMismatch() public {
        setRunner(alice);

        vm.expectRevert();

        vm.prank(alice);
        revokeMod.revokeERC20Approval(new address[](1), new address[](0));
    }

    function testRevokeERC721ApprovalSingle() public {
        setRunner(alice);

        erc721.mint(address(revokeMod), defaultId);

        vm.prank(address(revokeMod));
        erc721.approve(bob, defaultId);

        assertEq(erc721.getApproved(defaultId), address(bob));

        address[] memory tokens = new address[](1);
        tokens[0] = address(erc721);

        uint256[] memory ids = new uint256[](1);
        ids[0] = defaultId;

        vm.prank(alice);
        revokeMod.revokeERC721Approval(tokens, ids);

        assertEq(erc721.getApproved(defaultId), address(0));
    }

    function testRevokeERC721ApprovalDouble() public {
        setRunner(alice);

        erc721.mint(address(revokeMod), defaultId);
        erc721.mint(address(revokeMod), defaultId + 1);

        vm.prank(address(revokeMod));
        erc721.approve(bob, defaultId);

        vm.prank(address(revokeMod));
        erc721.approve(charlie, defaultId + 1);

        assertEq(erc721.getApproved(defaultId), bob);
        assertEq(erc721.getApproved(defaultId + 1), charlie);

        address[] memory tokens = new address[](2);
        tokens[0] = address(erc721);
        tokens[1] = address(erc721);

        uint256[] memory ids = new uint256[](2);
        ids[0] = defaultId;
        ids[1] = defaultId + 1;

        vm.prank(alice);
        revokeMod.revokeERC721Approval(tokens, ids);

        assertEq(erc721.getApproved(defaultId), address(0));
        assertEq(erc721.getApproved(defaultId + 1), address(0));
    }

    function testRevokeERC721EmptyList() public {
        setRunner(alice);

        vm.prank(alice);
        revokeMod.revokeERC721Approval(new address[](0), new uint256[](0));
    }

    function testRevokeERC721NotRunner() public {
        setRunner(alice);

        vm.expectRevert();

        vm.prank(bob);
        revokeMod.revokeERC721Approval(new address[](0), new uint256[](0));
    }

    function testRevokeERC721LengthMismatch() public {
        setRunner(alice);

        vm.expectRevert();

        vm.prank(alice);
        revokeMod.revokeERC721Approval(new address[](1), new uint256[](0));
    }

    function testRevokeERC6909ApprovalSingle() public {
        setRunner(alice);

        vm.prank(address(revokeMod));
        erc6909.approve(bob, defaultId, defaultAmount);

        assertEq(erc6909.allowance(address(revokeMod), bob, defaultId), defaultAmount);

        address[] memory tokens = new address[](1);
        tokens[0] = address(erc6909);

        uint256[] memory ids = new uint256[](1);
        ids[0] = defaultId;

        address[] memory operators = new address[](1);
        operators[0] = bob;

        vm.prank(alice);
        revokeMod.revokeERC6909Approval(tokens, ids, operators);

        assertEq(erc6909.allowance(address(revokeMod), bob, defaultId), 0);
    }

    function testRevokeERC6909ApprovalDouble() public {
        setRunner(alice);

        vm.prank(address(revokeMod));
        erc6909.approve(bob, defaultId, defaultAmount);

        vm.prank(address(revokeMod));
        erc6909.approve(charlie, defaultId, defaultAmount);

        assertEq(erc6909.allowance(address(revokeMod), bob, defaultId), defaultAmount);
        assertEq(erc6909.allowance(address(revokeMod), charlie, defaultId), defaultAmount);

        address[] memory tokens = new address[](2);
        tokens[0] = address(erc6909);
        tokens[1] = address(erc6909);

        uint256[] memory ids = new uint256[](2);
        ids[0] = defaultId;
        ids[1] = defaultId;

        address[] memory operators = new address[](2);
        operators[0] = bob;
        operators[1] = charlie;

        vm.prank(alice);
        revokeMod.revokeERC6909Approval(tokens, ids, operators);

        assertEq(erc6909.allowance(address(revokeMod), bob, defaultId), 0);
        assertEq(erc6909.allowance(address(revokeMod), charlie, defaultId), 0);
    }

    function testRevokeERC6909EmptyList() public {
        setRunner(alice);

        vm.prank(alice);
        revokeMod.revokeERC6909Approval(new address[](0), new uint256[](0), new address[](0));
    }

    function testRevokeERC6909NotRunner() public {
        setRunner(alice);

        vm.expectRevert();

        vm.prank(bob);
        revokeMod.revokeERC6909Approval(new address[](0), new uint256[](0), new address[](0));
    }

    function testRevokeERC6909LengthMismatch() public {
        setRunner(alice);

        vm.expectRevert();

        vm.prank(alice);
        revokeMod.revokeERC6909Approval(new address[](1), new uint256[](0), new address[](0));
    }

    function testRevokeApprovalForAllERC721Single() public {
        setRunner(alice);

        vm.prank(address(revokeMod));
        erc721.setApprovalForAll(bob, true);

        assert(erc721.isApprovedForAll(address(revokeMod), bob));

        address[] memory tokens = new address[](1);
        tokens[0] = address(erc721);

        address[] memory operators = new address[](1);
        operators[0] = bob;

        vm.prank(alice);
        revokeMod.revokeApprovalForAll(tokens, operators);

        assertFalse(erc721.isApprovedForAll(address(revokeMod), bob));
    }

    function testRevokeApprovalForAllERC721Double() public {
        setRunner(alice);

        vm.prank(address(revokeMod));
        erc721.setApprovalForAll(bob, true);

        vm.prank(address(revokeMod));
        erc721.setApprovalForAll(charlie, true);

        assertTrue(erc721.isApprovedForAll(address(revokeMod), bob));
        assertTrue(erc721.isApprovedForAll(address(revokeMod), charlie));

        address[] memory tokens = new address[](2);
        tokens[0] = address(erc721);
        tokens[1] = address(erc721);

        address[] memory operators = new address[](2);
        operators[0] = bob;
        operators[1] = charlie;

        vm.prank(alice);
        revokeMod.revokeApprovalForAll(tokens, operators);

        assertFalse(erc721.isApprovedForAll(address(revokeMod), bob));
        assertFalse(erc721.isApprovedForAll(address(revokeMod), charlie));
    }

    function testRevokeApprovalForAllERC1155Single() public {
        setRunner(alice);

        vm.prank(address(revokeMod));
        erc1155.setApprovalForAll(bob, true);

        assertTrue(erc1155.isApprovedForAll(address(revokeMod), bob));

        address[] memory tokens = new address[](1);
        tokens[0] = address(erc1155);

        address[] memory operators = new address[](1);
        operators[0] = bob;

        vm.prank(alice);
        revokeMod.revokeApprovalForAll(tokens, operators);

        assertFalse(erc1155.isApprovedForAll(address(revokeMod), bob));
    }

    function testRevokeApprovalForAllERC1155Double() public {
        setRunner(alice);

        vm.prank(address(revokeMod));
        erc1155.setApprovalForAll(bob, true);

        vm.prank(address(revokeMod));
        erc1155.setApprovalForAll(charlie, true);

        assertTrue(erc1155.isApprovedForAll(address(revokeMod), bob));
        assertTrue(erc1155.isApprovedForAll(address(revokeMod), charlie));

        address[] memory tokens = new address[](2);
        tokens[0] = address(erc1155);
        tokens[1] = address(erc1155);

        address[] memory operators = new address[](2);
        operators[0] = bob;
        operators[1] = charlie;

        vm.prank(alice);
        revokeMod.revokeApprovalForAll(tokens, operators);

        assertFalse(erc1155.isApprovedForAll(address(revokeMod), bob));
        assertFalse(erc1155.isApprovedForAll(address(revokeMod), charlie));
    }

    function testRevokeApprovalForAllMixed() public {
        setRunner(alice);

        vm.prank(address(revokeMod));
        erc721.setApprovalForAll(bob, true);

        vm.prank(address(revokeMod));
        erc1155.setApprovalForAll(charlie, true);

        assertTrue(erc721.isApprovedForAll(address(revokeMod), bob));
        assertTrue(erc1155.isApprovedForAll(address(revokeMod), charlie));

        address[] memory tokens = new address[](2);
        tokens[0] = address(erc721);
        tokens[1] = address(erc1155);

        address[] memory operators = new address[](2);
        operators[0] = bob;
        operators[1] = charlie;

        vm.prank(alice);
        revokeMod.revokeApprovalForAll(tokens, operators);

        assertFalse(erc721.isApprovedForAll(address(revokeMod), bob));
        assertFalse(erc1155.isApprovedForAll(address(revokeMod), charlie));
    }

    function testRevokeApprovalForAllEmptyList() public {
        setRunner(alice);

        vm.prank(alice);
        revokeMod.revokeApprovalForAll(new address[](0), new address[](0));
    }

    function testRevokeApprovalForAllNotRunner() public {
        setRunner(alice);

        vm.expectRevert();

        vm.prank(bob);
        revokeMod.revokeApprovalForAll(new address[](0), new address[](0));
    }

    function testRevokeApprovalForAllLengthMismatch() public {
        setRunner(alice);

        vm.expectRevert();

        vm.prank(alice);
        revokeMod.revokeApprovalForAll(new address[](1), new address[](0));
    }

    function testRevokeOperatorSingle() public {
        setRunner(alice);

        vm.prank(address(revokeMod));
        erc6909.setOperator(bob, true);

        assertTrue(erc6909.isOperator(address(revokeMod), bob));

        address[] memory tokens = new address[](1);
        tokens[0] = address(erc6909);

        address[] memory operators = new address[](1);
        operators[0] = bob;

        vm.prank(alice);
        revokeMod.revokeOperator(tokens, operators);

        assertFalse(erc6909.isOperator(address(revokeMod), bob));
    }

    function testRevokeOperatorDouble() public {
        setRunner(alice);

        vm.prank(address(revokeMod));
        erc6909.setOperator(bob, true);

        vm.prank(address(revokeMod));
        erc6909.setOperator(charlie, true);

        assertTrue(erc6909.isOperator(address(revokeMod), bob));
        assertTrue(erc6909.isOperator(address(revokeMod), charlie));

        address[] memory tokens = new address[](2);
        tokens[0] = address(erc6909);
        tokens[1] = address(erc6909);

        address[] memory operators = new address[](2);
        operators[0] = bob;
        operators[1] = charlie;

        vm.prank(alice);
        revokeMod.revokeOperator(tokens, operators);

        assertFalse(erc6909.isOperator(address(revokeMod), bob));
        assertFalse(erc6909.isOperator(address(revokeMod), charlie));
    }

    function testRevokeOperatorEmptyList() public {
        setRunner(alice);

        vm.prank(alice);
        revokeMod.revokeOperator(new address[](0), new address[](0));
    }

    function testRevokeOperatorNotRunner() public {
        setRunner(alice);

        vm.expectRevert();

        vm.prank(bob);
        revokeMod.revokeOperator(new address[](0), new address[](0));
    }

    function testRevokeOperatorLengthMismatch() public {
        setRunner(alice);

        vm.expectRevert();

        vm.prank(alice);
        revokeMod.revokeOperator(new address[](1), new address[](0));
    }

    function testFuzzRevokeERC20Approval(
        bool runnerIsActor,
        address runner,
        address actor,
        bytes32 salt,
        uint256[] memory amounts,
        bool lengthMismatch
    ) public {
        runner = runnerIsActor ? actor : runner;

        setRunner(runner);

        address[] memory tokens = new address[](lengthMismatch ? amounts.length + 1 : amounts.length);
        address[] memory spenders = new address[](amounts.length);

        for (uint256 i; i < amounts.length; i++) {
            tokens[i] = address(new MockERC20{ salt: salt }());
            spenders[i] = address(bytes20(keccak256(abi.encode(amounts[i]))));

            salt = keccak256(abi.encodePacked(salt));

            vm.prank(address(revokeMod));
            MockERC20(tokens[i]).approve(spenders[i], amounts[i]);

            assertEq(MockERC20(tokens[i]).allowance(address(revokeMod), spenders[i]), amounts[i]);
        }

        if (runner != actor || lengthMismatch) {
            vm.expectRevert();
        }

        vm.prank(actor);
        revokeMod.revokeERC20Approval(tokens, spenders);

        if (runner == actor && !lengthMismatch) {
            for (uint256 i; i < amounts.length; i++) {
                assertEq(MockERC20(tokens[i]).allowance(address(revokeMod), spenders[i]), 0);
            }
        }
    }

    function testFuzzRevokeERC721Approval(
        bool runnerIsActor,
        address runner,
        address actor,
        bytes32 salt,
        uint256[] memory ids,
        bool lengthMismatch
    ) public {
        runner = runnerIsActor ? actor : runner;

        setRunner(runner);

        address[] memory tokens = new address[](lengthMismatch ? ids.length + 1 : ids.length);
        address[] memory spenders = new address[](ids.length);

        for (uint256 i; i < ids.length; i++) {
            tokens[i] = address(new MockERC721{ salt: salt }());
            spenders[i] = address(bytes20(keccak256(abi.encode(ids[i]))));

            salt = keccak256(abi.encodePacked(salt));

            MockERC721(tokens[i]).mint(address(revokeMod), ids[i]);

            vm.prank(address(revokeMod));
            MockERC721(tokens[i]).approve(spenders[i], ids[i]);

            assertEq(MockERC721(tokens[i]).getApproved(ids[i]), spenders[i]);
        }

        if (runner != actor || lengthMismatch) {
            vm.expectRevert();
        }

        vm.prank(actor);
        revokeMod.revokeERC721Approval(tokens, ids);

        if (runner == actor && !lengthMismatch) {
            for (uint256 i; i < ids.length; i++) {
                assertEq(MockERC721(tokens[i]).getApproved(ids[i]), address(0));
            }
        }
    }

    function testFuzzRevokeERC6909Approval(
        bool runnerIsActor,
        address runner,
        address actor,
        bytes32 salt,
        uint256[] memory ids,
        bool lengthMismatch
    ) public {
        runner = runnerIsActor ? actor : runner;

        setRunner(runner);

        address[] memory tokens = new address[](lengthMismatch ? ids.length + 1 : ids.length);
        uint256[] memory amounts = new uint256[](ids.length);
        address[] memory operators = new address[](ids.length);

        for (uint256 i; i < ids.length; i++) {
            tokens[i] = address(new MockERC6909{ salt: salt }());
            amounts[i] = uint256(keccak256(abi.encode(i)));
            operators[i] = address(bytes20(keccak256(abi.encode(ids[i]))));

            salt = keccak256(abi.encodePacked(salt));

            vm.prank(address(revokeMod));
            MockERC6909(tokens[i]).approve(operators[i], ids[i], amounts[i]);

            assertEq(MockERC6909(tokens[i]).allowance(address(revokeMod), operators[i], ids[i]), amounts[i]);
        }

        if (runner != actor || lengthMismatch) {
            vm.expectRevert();
        }

        vm.prank(actor);
        revokeMod.revokeERC6909Approval(tokens, ids, operators);

        if (runner == actor && !lengthMismatch) {
            for (uint256 i; i < ids.length; i++) {
                assertEq(MockERC6909(tokens[i]).allowance(address(revokeMod), operators[i], ids[i]), 0);
            }
        }
    }

    function testFuzzRevokeApprovalForAll(
        bool runnerIsActor,
        address runner,
        address actor,
        bytes32 salt,
        uint256[] memory ids,
        bool lengthMismatch
    ) public {
        runner = runnerIsActor ? actor : runner;

        setRunner(runner);

        address[] memory tokens = new address[](lengthMismatch ? ids.length + 1 : ids.length);
        address[] memory operators = new address[](ids.length);

        for (uint256 i; i < ids.length; i++) {
            bool isERC721 = uint256(salt) % 2 == 0;
            tokens[i] = isERC721 ? address(new MockERC721{ salt: salt }()) : address(new MockERC1155{ salt: salt }());
            operators[i] = address(bytes20(keccak256(abi.encode(ids[i]))));

            salt = keccak256(abi.encodePacked(salt));

            vm.prank(address(revokeMod));
            MockERC721(tokens[i]).setApprovalForAll(operators[i], true);

            assertTrue(MockERC721(tokens[i]).isApprovedForAll(address(revokeMod), operators[i]));
        }

        if (runner != actor || lengthMismatch) {
            vm.expectRevert();
        }

        vm.prank(actor);
        revokeMod.revokeApprovalForAll(tokens, operators);

        if (runner == actor && !lengthMismatch) {
            for (uint256 i; i < tokens.length; i++) {
                assertFalse(MockERC721(tokens[i]).isApprovedForAll(address(revokeMod), operators[i]));
            }
        }
    }

    function testFuzzRevokeOperator(
        bool runnerIsActor,
        address runner,
        address actor,
        bytes32 salt,
        uint256[] memory ids,
        bool lengthMismatch
    ) public {
        runner = runnerIsActor ? actor : runner;

        setRunner(runner);

        address[] memory tokens = new address[](lengthMismatch ? ids.length + 1 : ids.length);
        address[] memory operators = new address[](ids.length);

        for (uint256 i; i < ids.length; i++) {
            tokens[i] = address(new MockERC6909{ salt: salt }());
            operators[i] = address(bytes20(keccak256(abi.encode(ids[i]))));

            salt = keccak256(abi.encodePacked(salt));

            vm.prank(address(revokeMod));
            MockERC6909(tokens[i]).setOperator(operators[i], true);

            assertTrue(MockERC6909(tokens[i]).isOperator(address(revokeMod), operators[i]));
        }

        if (runner != actor || lengthMismatch) {
            vm.expectRevert();
        }

        vm.prank(actor);
        revokeMod.revokeOperator(tokens, operators);

        if (runner == actor && !lengthMismatch) {
            for (uint256 i; i < tokens.length; i++) {
                assertFalse(MockERC6909(tokens[i]).isOperator(address(revokeMod), operators[i]));
            }
        }
    }

    function setRunner(address runner) internal {
        vm.store(address(revokeMod), bytes32(uint256(1)), bytes32(uint256(uint160(runner))));
    }
}
