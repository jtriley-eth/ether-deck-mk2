// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import { Test, console } from "../../lib/forge-std/src/Test.sol";

import { FlashMod } from "../../src/mods/FlashMod.sol";
import { DifferentialFlashMod } from "./implementations/DifferentialFlashMod.sol";
import { MockFlashReceiver } from "../mock/MockFlashReceiver.sol";
import { MockERC20 } from "../mock/MockERC20.sol";

contract DifferentialFlashModTest is Test {
    FlashMod internal fastFlash;
    DifferentialFlashMod internal slowFlash;

    uint256 internal constant divisor = 10_000;

    function setUp() public {
        fastFlash = new FlashMod();
        slowFlash = new DifferentialFlashMod();
    }

    function testFuzzDiffSetFlashFeeFactor(
        bool runnerIsActor,
        address runner,
        address actor,
        address token,
        uint256 factor
    ) public {
        runner = runnerIsActor ? actor : runner;

        setRunner(runner);

        vm.startPrank(actor);

        assertEq(0, getFlashFeeFactor(address(fastFlash), token));
        assertEq(0, getFlashFeeFactor(address(slowFlash), token));

        if (runner != actor || factor > divisor) {
            vm.expectRevert();
            fastFlash.setFlashFeeFactor(token, factor);

            vm.expectRevert();
            slowFlash.setFlashFeeFactor(token, factor);
        } else {
            fastFlash.setFlashFeeFactor(token, factor);
            slowFlash.setFlashFeeFactor(token, factor);

            assertEq(factor, getFlashFeeFactor(address(fastFlash), token));
            assertEq(factor, getFlashFeeFactor(address(slowFlash), token));
        }

        vm.stopPrank();
    }

    function testFuzzDiffMaxFlashLoan(bool supported, address runner, uint256 amount, bytes32 salt) public {
        amount = bound(amount, 0, type(uint256).max / 2);
        MockERC20 token = new MockERC20{ salt: salt }();

        token.mint(address(fastFlash), amount);
        token.mint(address(slowFlash), amount);

        if (supported) {
            setRunner(runner);

            vm.startPrank(runner);
            fastFlash.setFlashFeeFactor(address(token), 1);
            slowFlash.setFlashFeeFactor(address(token), 1);
            vm.stopPrank();
        }

        assertEq(supported ? amount : 0, fastFlash.maxFlashLoan(address(token)));
        assertEq(supported ? amount : 0, slowFlash.maxFlashLoan(address(token)));
    }

    function testFuzzDiffFlashFee(
        address runner,
        address token,
        uint256 amount,
        uint256 factor
    ) public {
        factor = bound(factor, 0, divisor);

        bool throws = factor == 0 || amount > type(uint256).max / factor;

        assertEq(0, getFlashFeeFactor(address(fastFlash), token));
        assertEq(0, getFlashFeeFactor(address(slowFlash), token));

        setRunner(runner);

        vm.startPrank(runner);
        fastFlash.setFlashFeeFactor(token, factor);
        slowFlash.setFlashFeeFactor(token, factor);
        vm.stopPrank();

        if (throws) {
            vm.expectRevert();
            fastFlash.flashFee(token, amount);

            vm.expectRevert();
            slowFlash.flashFee(token, amount);
        } else {
            uint256 flashFee = amount * factor / divisor;

            assertEq(flashFee, fastFlash.flashFee(token, amount));
            assertEq(flashFee, slowFlash.flashFee(token, amount));
        }
    }

    function testFuzzDiffFlashLoan(
        address runner,
        uint256 receiverBalance,
        uint256 modBalance,
        uint256 loanAmount,
        uint256 factor,
        bytes calldata data,
        bytes32 salt
    ) public {
        factor = bound(factor, 0, divisor);
        modBalance = bound(modBalance, 0, type(uint256).max / 4);
        receiverBalance = bound(receiverBalance, 0, type(uint256).max / 2 - modBalance);
        bool throws = factor == 0 || loanAmount > modBalance || loanAmount > type(uint256).max / factor;
        unchecked { throws = throws || loanAmount * factor / divisor > receiverBalance; }

        MockERC20 token = new MockERC20{ salt: salt }();
        MockFlashReceiver fastReceiver = new MockFlashReceiver{ salt: salt }();
        MockFlashReceiver slowReceiver = new MockFlashReceiver{ salt: keccak256(abi.encode(salt)) }();

        token.mint(address(fastFlash), modBalance);
        token.mint(address(slowFlash), modBalance);
        token.mint(address(fastReceiver), receiverBalance);
        token.mint(address(slowReceiver), receiverBalance);

        assertEq(token.balanceOf(address(fastReceiver)), receiverBalance);
        assertEq(token.balanceOf(address(slowReceiver)), receiverBalance);
        assertEq(token.balanceOf(address(fastFlash)), modBalance);
        assertEq(token.balanceOf(address(slowFlash)), modBalance);

        setRunner(runner);

        vm.startPrank(runner);
        fastFlash.setFlashFeeFactor(address(token), factor);
        slowFlash.setFlashFeeFactor(address(token), factor);
        vm.stopPrank();

        if (throws) {
            vm.expectRevert();
            fastFlash.flashLoan(address(fastReceiver), address(token), loanAmount, data);

            vm.expectRevert();
            slowFlash.flashLoan(address(slowReceiver), address(token), loanAmount, data);
        } else {
            uint256 flashFee = loanAmount * factor / divisor;

            assertTrue(fastFlash.flashLoan(address(fastReceiver), address(token), loanAmount, data));
            assertTrue(slowFlash.flashLoan(address(slowReceiver), address(token), loanAmount, data));

            assertEq(token.balanceOf(address(fastReceiver)), receiverBalance - flashFee);
            assertEq(token.balanceOf(address(slowReceiver)), receiverBalance - flashFee);
            assertEq(token.balanceOf(address(fastFlash)), modBalance + flashFee);
            assertEq(token.balanceOf(address(slowFlash)), modBalance + flashFee);
        }
    }

    function setRunner(address runner) internal {
        vm.store(address(fastFlash), bytes32(uint256(1)), bytes32(uint256(uint160(runner))));
        vm.store(address(slowFlash), bytes32(uint256(1)), bytes32(uint256(uint160(runner))));
    }

    function getFlashFeeFactor(address mod, address token) internal view returns (uint256) {
        return uint256(
            vm.load(
                address(mod), keccak256(abi.encode(token, uint256(keccak256("EtherDeckMk2.FlashFeeSlotIndex")) - 1))
            )
        );
    }
}
