// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import { Test } from "../lib/forge-std/src/Test.sol";

import { FlashMod } from "../src/mods/FlashMod.sol";
import { MockERC20 } from "./mock/MockERC20.sol";
import { MockFlashReceiver } from "./mock/MockFlashReceiver.sol";

contract FlashModTest is Test {
    FlashMod internal flashMod;
    MockERC20 internal token;
    MockFlashReceiver internal flashReceiver;
    address internal alice = vm.addr(1);
    address internal bob = vm.addr(2);
    uint256 internal defaultAmount = 100_000;
    uint256 internal divisor = 10_000;
    uint256 internal defaultFactor = 100;

    modifier asActor(address actor) {
        vm.store(address(flashMod), bytes32(uint256(1)), bytes32(uint256(uint160(actor))));
        vm.startPrank(actor);
        _;
        vm.stopPrank();
    }

    function setUp() public {
        flashMod = new FlashMod();
        token = new MockERC20();
        flashReceiver = new MockFlashReceiver();
    }

    function testSetFlashFeeFactor() public asActor(alice) {
        assertEq(bytes32(0), vm.load(address(flashMod), flashFeeFactorSlot(token)));

        flashMod.setFlashFeeFactor(address(token), defaultFactor);

        assertEq(bytes32(defaultFactor), vm.load(address(flashMod), flashFeeFactorSlot(token)));
    }

    function testSetFlashFeeFactorNotRunner() public {
        vm.store(address(flashMod), bytes32(uint256(1)), bytes32(uint256(uint160(alice))));
        vm.expectRevert();

        vm.prank(bob);
        flashMod.setFlashFeeFactor(address(token), defaultFactor);
    }

    function testMaxFlashLoan() public asActor(alice) {
        assertEq(flashMod.maxFlashLoan(address(token)), 0);

        flashMod.setFlashFeeFactor(address(token), 1);

        token.mint(address(flashMod), defaultAmount);

        assertEq(flashMod.maxFlashLoan(address(token)), defaultAmount);
    }

    function testMaxFlashLoanNotSupported() public {
        token.mint(address(flashMod), defaultAmount);

        assertEq(0, flashMod.maxFlashLoan(address(token)));
    }

    function testFlashFee() public asActor(alice) {
        uint256 flashFee = defaultAmount * defaultFactor / divisor;

        assertEq(bytes32(0), vm.load(address(flashMod), flashFeeFactorSlot(token)));

        flashMod.setFlashFeeFactor(address(token), defaultFactor);

        assertEq(flashMod.flashFee(address(token), defaultAmount), flashFee);
    }

    function testFlashFeeUnsupported() public asActor(alice) {
        assertEq(bytes32(0), vm.load(address(flashMod), flashFeeFactorSlot(token)));

        vm.expectRevert();
        flashMod.flashFee(address(token), defaultAmount);
    }

    function testFlashFeeOverflow() public asActor(alice) {
        assertEq(bytes32(0), vm.load(address(flashMod), flashFeeFactorSlot(token)));

        flashMod.setFlashFeeFactor(address(token), defaultFactor);

        vm.expectRevert();
        flashMod.flashFee(address(token), type(uint256).max);
    }

    function testFlashLoan() public asActor(alice) {
        uint256 flashFee = defaultAmount * defaultFactor / divisor;
        assertEq(token.balanceOf(address(flashReceiver)), 0);
        assertEq(token.balanceOf(address(flashMod)), 0);

        flashMod.setFlashFeeFactor(address(token), defaultFactor);

        assertEq(flashMod.flashFee(address(token), defaultAmount), flashFee);

        token.mint(address(flashReceiver), flashFee);
        token.mint(address(flashMod), defaultAmount);

        assertEq(token.balanceOf(address(flashReceiver)), flashFee);
        assertEq(token.balanceOf(address(flashMod)), defaultAmount);

        flashMod.flashLoan(address(flashReceiver), address(token), defaultAmount, hex"aabbccdd");

        assertEq(token.balanceOf(address(flashReceiver)), 0);
        assertEq(token.balanceOf(address(flashMod)), defaultAmount + flashFee);
    }

    function testFuzzSetFlashFeeFactor(address actor, uint256 factor, bool isRunner) public {
        vm.assume(actor != address(0));

        if (isRunner) {
            vm.store(address(flashMod), bytes32(uint256(1)), bytes32(uint256(uint160(actor))));
        } else {
            vm.expectRevert();
        }

        assertEq(bytes32(0), vm.load(address(flashMod), flashFeeFactorSlot(token)));

        vm.prank(actor);
        flashMod.setFlashFeeFactor(address(token), factor);

        if (isRunner) {
            assertEq(bytes32(factor), vm.load(address(flashMod), flashFeeFactorSlot(token)));
        }
    }

    function testFuzzMaxFlashLoan(bool supported, address actor, uint256 amount) public asActor(actor) {
        assertEq(flashMod.maxFlashLoan(address(token)), 0);

        if (supported) flashMod.setFlashFeeFactor(address(token), 1);

        token.mint(address(flashMod), amount);

        assertEq(flashMod.maxFlashLoan(address(token)), supported ? amount : 0);
    }

    function testFuzzFlashFee(address actor, uint256 amount, uint256 factor) public asActor(actor) {
        bool throws = factor == 0 || amount > type(uint256).max / factor;

        assertEq(bytes32(0), vm.load(address(flashMod), flashFeeFactorSlot(token)));

        flashMod.setFlashFeeFactor(address(token), factor);

        if (throws) {
            vm.expectRevert();
        }

        flashMod.flashFee(address(token), amount);

        if (!throws) {
            assertEq(flashMod.flashFee(address(token), amount), amount * factor / divisor);
        }
    }

    function testFuzzFlashLoan(
        address actor,
        uint256 receiverBalance,
        uint256 modBalance,
        uint256 loanAmount,
        uint256 factor
    ) public asActor(actor) {
        receiverBalance = bound(receiverBalance, 0, type(uint256).max - modBalance);
        bool throws = factor == 0 || loanAmount > type(uint256).max / factor;
        uint256 flashFee;
        unchecked { flashFee = loanAmount * factor / divisor; }

        assertEq(bytes32(0), vm.load(address(flashMod), flashFeeFactorSlot(token)));

        flashMod.setFlashFeeFactor(address(token), factor);

        assertEq(bytes32(factor), vm.load(address(flashMod), flashFeeFactorSlot(token)));

        token.mint(address(flashReceiver), receiverBalance);
        token.mint(address(flashMod), modBalance);

        assertEq(token.balanceOf(address(flashReceiver)), receiverBalance);
        assertEq(token.balanceOf(address(flashMod)), modBalance);

        if (throws || receiverBalance < flashFee || loanAmount > modBalance) {
            vm.expectRevert();
        }

        flashMod.flashLoan(address(flashReceiver), address(token), loanAmount, hex"aabbccdd");

        if (throws || receiverBalance < flashFee || loanAmount > modBalance) {
            assertEq(token.balanceOf(address(flashReceiver)), receiverBalance);
            assertEq(token.balanceOf(address(flashMod)), modBalance);
        } else {
            assertEq(token.balanceOf(address(flashReceiver)), receiverBalance - flashFee);
            assertEq(token.balanceOf(address(flashMod)), modBalance + flashFee);
        }
    }

    function flashFeeFactorSlot(MockERC20 _token) internal pure returns (bytes32) {
        return keccak256(abi.encode(_token, uint256(keccak256("EtherDeckMk2.FlashFeeSlotIndex")) - 1));
    }
}
