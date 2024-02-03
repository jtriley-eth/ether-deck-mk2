// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import { Test } from "../lib/forge-std/src/Test.sol";

import { MassTransferMod } from "../src/mods/MassTransferMod.sol";

import { MockERC20 } from "./mock/MockERC20.sol";
import { MockERC721 } from "./mock/MockERC721.sol";
import { MockERC1155 } from "./mock/MockERC1155.sol";
import { MockERC6909 } from "./mock/MockERC6909.sol";

contract MassTransferModTest is Test {
    MassTransferMod internal transferMod;
    MockERC20 internal erc20;
    MockERC721 internal erc721;
    MockERC1155 internal erc1155;
    MockERC6909 internal erc6909;

    address internal alice = vm.addr(1);
    address internal bob = vm.addr(2);
    address internal charlie = vm.addr(3);
    uint256 internal defaultAmount = 1;
    uint256 internal defaultId = 2;

    function setUp() public {
        transferMod = new MassTransferMod();
        erc20 = new MockERC20();
        erc721 = new MockERC721();
        erc1155 = new MockERC1155();
        erc6909 = new MockERC6909();
    }

    function testTransferERC20Single() public {
        setRunner(alice);

        erc20.mint(address(transferMod), defaultAmount);

        assertEq(erc20.balanceOf(address(transferMod)), defaultAmount);
        assertEq(erc20.balanceOf(bob), 0);

        address[] memory tokens = new address[](1);
        tokens[0] = address(erc20);

        address[] memory receivers = new address[](1);
        receivers[0] = bob;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = defaultAmount;

        vm.expectCall(address(erc20), abi.encodeCall(MockERC20.transfer, (bob, defaultAmount)));

        vm.prank(alice);
        transferMod.transferERC20(tokens, receivers, amounts);

        assertEq(erc20.balanceOf(address(transferMod)), 0);
        assertEq(erc20.balanceOf(bob), defaultAmount);
    }

    function testTransferERC20Double() public {
        setRunner(alice);

        erc20.mint(address(transferMod), defaultAmount * 2);

        assertEq(erc20.balanceOf(address(transferMod)), defaultAmount * 2);
        assertEq(erc20.balanceOf(bob), 0);
        assertEq(erc20.balanceOf(charlie), 0);

        address[] memory tokens = new address[](2);
        tokens[0] = address(erc20);
        tokens[1] = address(erc20);

        address[] memory receivers = new address[](2);
        receivers[0] = bob;
        receivers[1] = charlie;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = defaultAmount;
        amounts[1] = defaultAmount;

        vm.expectCall(address(erc20), abi.encodeCall(MockERC20.transfer, (bob, defaultAmount)));
        vm.expectCall(address(erc20), abi.encodeCall(MockERC20.transfer, (charlie, defaultAmount)));

        vm.prank(alice);
        transferMod.transferERC20(tokens, receivers, amounts);

        assertEq(erc20.balanceOf(address(transferMod)), 0);
        assertEq(erc20.balanceOf(bob), defaultAmount);
        assertEq(erc20.balanceOf(charlie), defaultAmount);
    }

    function testTransferERC20Empty() public {
        setRunner(alice);

        vm.prank(alice);
        transferMod.transferERC20(new address[](0), new address[](0), new uint256[](0));
    }

    function testTransferERC20NotRunner() public {
        setRunner(alice);

        vm.expectRevert();

        vm.prank(bob);
        transferMod.transferERC20(new address[](0), new address[](0), new uint256[](0));
    }

    function testTransferERC20MismatchLength() public {
        setRunner(alice);

        vm.expectRevert();

        vm.prank(alice);
        transferMod.transferERC20(new address[](1), new address[](2), new uint256[](2));
    }

    function testTransferERC721Single() public {
        setRunner(alice);

        erc721.mint(address(transferMod), defaultId);

        assertEq(erc721.ownerOf(defaultId), address(transferMod));
        assertEq(erc721.balanceOf(address(transferMod)), 1);
        assertEq(erc721.balanceOf(bob), 0);

        address[] memory tokens = new address[](1);
        tokens[0] = address(erc721);

        address[] memory receivers = new address[](1);
        receivers[0] = bob;

        uint256[] memory ids = new uint256[](1);
        ids[0] = defaultId;

        vm.expectCall(address(erc721), abi.encodeCall(MockERC721.transferFrom, (address(transferMod), bob, defaultId)));

        vm.prank(alice);
        transferMod.transferERC721(tokens, receivers, ids);

        assertEq(erc721.ownerOf(defaultId), bob);
        assertEq(erc721.balanceOf(address(transferMod)), 0);
        assertEq(erc721.balanceOf(bob), 1);
    }

    function testTransferERC721Double() public {
        setRunner(alice);

        erc721.mint(address(transferMod), defaultId);
        erc721.mint(address(transferMod), defaultId + 1);

        assertEq(erc721.ownerOf(defaultId), address(transferMod));
        assertEq(erc721.ownerOf(defaultId + 1), address(transferMod));
        assertEq(erc721.balanceOf(address(transferMod)), 2);
        assertEq(erc721.balanceOf(bob), 0);
        assertEq(erc721.balanceOf(charlie), 0);

        address[] memory tokens = new address[](2);
        tokens[0] = address(erc721);
        tokens[1] = address(erc721);

        address[] memory receivers = new address[](2);
        receivers[0] = bob;
        receivers[1] = charlie;

        uint256[] memory ids = new uint256[](2);
        ids[0] = defaultId;
        ids[1] = defaultId + 1;

        vm.expectCall(address(erc721), abi.encodeCall(MockERC721.transferFrom, (address(transferMod), bob, defaultId)));
        vm.expectCall(
            address(erc721), abi.encodeCall(MockERC721.transferFrom, (address(transferMod), charlie, defaultId + 1))
        );

        vm.prank(alice);
        transferMod.transferERC721(tokens, receivers, ids);

        assertEq(erc721.ownerOf(defaultId), bob);
        assertEq(erc721.ownerOf(defaultId + 1), charlie);
        assertEq(erc721.balanceOf(address(transferMod)), 0);
        assertEq(erc721.balanceOf(bob), 1);
        assertEq(erc721.balanceOf(charlie), 1);
    }

    function testTransferERC721Empty() public {
        setRunner(alice);

        vm.prank(alice);
        transferMod.transferERC721(new address[](0), new address[](0), new uint256[](0));
    }

    function testTransferERC721NotRunner() public {
        setRunner(alice);

        vm.expectRevert();

        vm.prank(bob);
        transferMod.transferERC721(new address[](0), new address[](0), new uint256[](0));
    }

    function testTransferERC721MismatchLength() public {
        setRunner(alice);

        vm.expectRevert();

        vm.prank(alice);
        transferMod.transferERC721(new address[](1), new address[](2), new uint256[](2));
    }

    function testTransferERC1155Single() public {
        setRunner(alice);

        erc1155.mint(address(transferMod), defaultId, defaultAmount);

        assertEq(erc1155.balanceOf(address(transferMod), defaultId), defaultAmount);
        assertEq(erc1155.balanceOf(bob, defaultId), 0);

        address[] memory tokens = new address[](1);
        tokens[0] = address(erc1155);

        address[] memory receivers = new address[](1);
        receivers[0] = bob;

        uint256[] memory ids = new uint256[](1);
        ids[0] = defaultId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = defaultAmount;

        vm.expectCall(
            address(erc1155),
            abi.encodeCall(
                MockERC1155.safeTransferFrom, (address(transferMod), bob, defaultId, defaultAmount, new bytes(0))
            )
        );

        vm.prank(alice);
        transferMod.transferERC1155(tokens, receivers, ids, amounts);

        assertEq(erc1155.balanceOf(address(transferMod), defaultId), 0);
        assertEq(erc1155.balanceOf(bob, defaultId), defaultAmount);
    }

    function testTransferERC1155Double() public {
        setRunner(alice);

        erc1155.mint(address(transferMod), defaultId, defaultAmount * 2);

        assertEq(erc1155.balanceOf(address(transferMod), defaultId), defaultAmount * 2);
        assertEq(erc1155.balanceOf(bob, defaultId), 0);
        assertEq(erc1155.balanceOf(charlie, defaultId), 0);

        address[] memory tokens = new address[](2);
        tokens[0] = address(erc1155);
        tokens[1] = address(erc1155);

        address[] memory receivers = new address[](2);
        receivers[0] = bob;
        receivers[1] = charlie;

        uint256[] memory ids = new uint256[](2);
        ids[0] = defaultId;
        ids[1] = defaultId;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = defaultAmount;
        amounts[1] = defaultAmount;

        vm.expectCall(
            address(erc1155),
            abi.encodeCall(
                MockERC1155.safeTransferFrom, (address(transferMod), bob, defaultId, defaultAmount, new bytes(0))
            )
        );
        vm.expectCall(
            address(erc1155),
            abi.encodeCall(
                MockERC1155.safeTransferFrom, (address(transferMod), charlie, defaultId, defaultAmount, new bytes(0))
            )
        );

        vm.prank(alice);
        transferMod.transferERC1155(tokens, receivers, ids, amounts);

        assertEq(erc1155.balanceOf(address(transferMod), defaultId), 0);
        assertEq(erc1155.balanceOf(bob, defaultId), defaultAmount);
        assertEq(erc1155.balanceOf(charlie, defaultId), defaultAmount);
    }

    function testTransferERC1155Empty() public {
        setRunner(alice);

        vm.prank(alice);
        transferMod.transferERC1155(new address[](0), new address[](0), new uint256[](0), new uint256[](0));
    }

    function testTransferERC1155NotRunner() public {
        setRunner(alice);

        vm.expectRevert();

        vm.prank(bob);
        transferMod.transferERC1155(new address[](0), new address[](0), new uint256[](0), new uint256[](0));
    }

    function testTransferERC1155MismatchLength() public {
        setRunner(alice);

        vm.expectRevert();

        vm.prank(alice);
        transferMod.transferERC1155(new address[](1), new address[](2), new uint256[](2), new uint256[](2));
    }

    function testTransferERC6909Single() public {
        setRunner(alice);

        erc6909.mint(address(transferMod), defaultId, defaultAmount);

        assertEq(erc6909.balanceOf(address(transferMod), defaultId), defaultAmount);
        assertEq(erc6909.balanceOf(bob, defaultId), 0);

        address[] memory tokens = new address[](1);
        tokens[0] = address(erc6909);

        address[] memory receivers = new address[](1);
        receivers[0] = bob;

        uint256[] memory ids = new uint256[](1);
        ids[0] = defaultId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = defaultAmount;

        vm.expectCall(address(erc6909), abi.encodeCall(MockERC6909.transfer, (bob, defaultId, defaultAmount)));

        vm.prank(alice);
        transferMod.transferERC6909(tokens, receivers, ids, amounts);

        assertEq(erc6909.balanceOf(address(transferMod), defaultId), 0);
        assertEq(erc6909.balanceOf(bob, defaultId), defaultAmount);
    }

    function testTransferERC6909Double() public {
        setRunner(alice);

        erc6909.mint(address(transferMod), defaultId, defaultAmount * 2);

        assertEq(erc6909.balanceOf(address(transferMod), defaultId), defaultAmount * 2);
        assertEq(erc6909.balanceOf(bob, defaultId), 0);
        assertEq(erc6909.balanceOf(charlie, defaultId), 0);

        address[] memory tokens = new address[](2);
        tokens[0] = address(erc6909);
        tokens[1] = address(erc6909);

        address[] memory receivers = new address[](2);
        receivers[0] = bob;
        receivers[1] = charlie;

        uint256[] memory ids = new uint256[](2);
        ids[0] = defaultId;
        ids[1] = defaultId;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = defaultAmount;
        amounts[1] = defaultAmount;

        vm.expectCall(address(erc6909), abi.encodeCall(MockERC6909.transfer, (bob, defaultId, defaultAmount)));
        vm.expectCall(address(erc6909), abi.encodeCall(MockERC6909.transfer, (charlie, defaultId, defaultAmount)));

        vm.prank(alice);
        transferMod.transferERC6909(tokens, receivers, ids, amounts);

        assertEq(erc6909.balanceOf(address(transferMod), defaultId), 0);
        assertEq(erc6909.balanceOf(bob, defaultId), defaultAmount);
        assertEq(erc6909.balanceOf(charlie, defaultId), defaultAmount);
    }

    function testTransferERC6909Empty() public {
        setRunner(alice);

        vm.prank(alice);
        transferMod.transferERC6909(new address[](0), new address[](0), new uint256[](0), new uint256[](0));
    }

    function testTransferERC6909NotRunner() public {
        setRunner(alice);

        vm.expectRevert();

        vm.prank(bob);
        transferMod.transferERC6909(new address[](0), new address[](0), new uint256[](0), new uint256[](0));
    }

    function testTransferERC6909MismatchLength() public {
        setRunner(alice);

        vm.expectRevert();

        vm.prank(alice);
        transferMod.transferERC6909(new address[](1), new address[](2), new uint256[](2), new uint256[](2));
    }

    function testFuzzTransferERC20(
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
        address[] memory receivers = new address[](amounts.length);

        for (uint256 i; i < amounts.length; i++) {
            tokens[i] = address(new MockERC20{ salt: salt }());
            receivers[i] = address(bytes20(keccak256(abi.encode(amounts[i]))));
            salt = keccak256(abi.encode(salt));

            MockERC20(tokens[i]).mint(address(transferMod), amounts[i]);
            assertEq(MockERC20(tokens[i]).balanceOf(address(transferMod)), amounts[i]);
            assertEq(MockERC20(tokens[i]).balanceOf(receivers[i]), 0);
        }

        if (runner != actor || lengthMismatch) {
            vm.expectRevert();
        }

        vm.prank(actor);
        transferMod.transferERC20(tokens, receivers, amounts);

        if (runner == actor && !lengthMismatch) {
            for (uint256 i; i < amounts.length; i++) {
                assertEq(MockERC20(tokens[i]).balanceOf(address(transferMod)), 0);
                assertEq(MockERC20(tokens[i]).balanceOf(receivers[i]), amounts[i]);
            }
        }
    }

    function testFuzzTransferERC721(
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
        address[] memory receivers = new address[](ids.length);

        for (uint256 i; i < ids.length; i++) {
            tokens[i] = address(new MockERC721{ salt: salt }());
            receivers[i] = address(bytes20(keccak256(abi.encode(ids[i]))));
            salt = keccak256(abi.encode(salt));

            MockERC721(tokens[i]).mint(address(transferMod), ids[i]);
            assertEq(MockERC721(tokens[i]).ownerOf(ids[i]), address(transferMod));
            assertEq(MockERC721(tokens[i]).balanceOf(address(transferMod)), 1);
            assertEq(MockERC721(tokens[i]).balanceOf(receivers[i]), 0);
        }

        if (runner != actor || lengthMismatch) {
            vm.expectRevert();
        }

        vm.prank(actor);
        transferMod.transferERC721(tokens, receivers, ids);

        if (runner == actor && !lengthMismatch) {
            for (uint256 i; i < ids.length; i++) {
                assertEq(MockERC721(tokens[i]).ownerOf(ids[i]), receivers[i]);
                assertEq(MockERC721(tokens[i]).balanceOf(address(transferMod)), 0);
                assertEq(MockERC721(tokens[i]).balanceOf(receivers[i]), 1);
            }
        }
    }

    function testFuzzTransferERC1155(
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
        address[] memory receivers = new address[](amounts.length);
        uint256[] memory ids = new uint256[](amounts.length);

        for (uint256 i; i < amounts.length; i++) {
            tokens[i] = address(new MockERC1155{ salt: salt }());
            receivers[i] = address(bytes20(keccak256(abi.encode(ids[i], amounts[i]))));
            ids[i] = uint256(salt);
            salt = keccak256(abi.encode(salt));

            MockERC1155(tokens[i]).mint(address(transferMod), ids[i], amounts[i]);
            assertEq(MockERC1155(tokens[i]).balanceOf(address(transferMod), ids[i]), amounts[i]);
            assertEq(MockERC1155(tokens[i]).balanceOf(receivers[i], ids[i]), 0);
        }

        if (runner != actor || lengthMismatch) {
            vm.expectRevert();
        }

        vm.prank(actor);
        transferMod.transferERC1155(tokens, receivers, ids, amounts);

        if (runner == actor && !lengthMismatch) {
            for (uint256 i; i < amounts.length; i++) {
                assertEq(MockERC1155(tokens[i]).balanceOf(address(transferMod), ids[i]), 0);
                assertEq(MockERC1155(tokens[i]).balanceOf(receivers[i], ids[i]), amounts[i]);
            }
        }
    }

    function testFuzzTransferERC6909(
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
        address[] memory receivers = new address[](amounts.length);
        uint256[] memory ids = new uint256[](amounts.length);

        for (uint256 i; i < amounts.length; i++) {
            tokens[i] = address(new MockERC6909{ salt: salt }());
            receivers[i] = address(bytes20(keccak256(abi.encode(ids[i], amounts[i]))));
            ids[i] = uint256(salt);
            salt = keccak256(abi.encode(salt));

            MockERC6909(tokens[i]).mint(address(transferMod), ids[i], amounts[i]);
            assertEq(MockERC6909(tokens[i]).balanceOf(address(transferMod), ids[i]), amounts[i]);
            assertEq(MockERC6909(tokens[i]).balanceOf(receivers[i], ids[i]), 0);
        }

        if (runner != actor || lengthMismatch) {
            vm.expectRevert();
        }

        vm.prank(actor);
        transferMod.transferERC6909(tokens, receivers, ids, amounts);

        if (runner == actor && !lengthMismatch) {
            for (uint256 i; i < amounts.length; i++) {
                assertEq(MockERC6909(tokens[i]).balanceOf(address(transferMod), ids[i]), 0);
                assertEq(MockERC6909(tokens[i]).balanceOf(receivers[i], ids[i]), amounts[i]);
            }
        }
    }

    function setRunner(address runner) internal {
        vm.store(address(transferMod), bytes32(uint256(1)), bytes32(uint256(uint160(runner))));
    }
}
