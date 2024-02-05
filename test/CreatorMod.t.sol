// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

import { Test } from "../lib/forge-std/src/Test.sol";

import { CreatorMod } from "../src/mods/CreatorMod.sol";
import { MockTarget } from "./mock/MockTarget.sol";

contract CreatorModTest is Test {
    CreatorMod internal creatorMod;
    address internal alice = vm.addr(1);
    address internal bob = vm.addr(2);
    uint256 defaultValue = 1;
    bytes32 defaultSalt = bytes32(uint256(0x01));

    bytes internal constant failingInitcode = hex"5f5ffd";

    function setUp() public {
        creatorMod = new CreatorMod();
    }

    function testCreate() public {
        setRunner(alice);

        vm.deal(alice, defaultValue);

        vm.prank(alice);
        address deployment = creatorMod.create{ value: defaultValue }(defaultValue, type(MockTarget).creationCode);

        assertNotEq(deployment, address(0));
        assertEq(deployment.codehash, address(new MockTarget()).codehash);
        assertEq(deployment.balance, defaultValue);
    }

    function testCreateFromModBalance() public {
        setRunner(alice);

        vm.deal(address(creatorMod), defaultValue);

        vm.prank(alice);
        address deployment = creatorMod.create(defaultValue, type(MockTarget).creationCode);

        assertNotEq(deployment, address(0));
        assertEq(deployment.codehash, address(new MockTarget()).codehash);
        assertEq(deployment.balance, defaultValue);
    }

    function testCreateNoValue() public {
        setRunner(alice);

        vm.prank(alice);
        address deployment = creatorMod.create(0, type(MockTarget).creationCode);

        assertNotEq(deployment, address(0));
        assertEq(deployment.codehash, address(new MockTarget()).codehash);
        assertEq(deployment.balance, 0);
    }

    function testCreateNotRunner() public {
        setRunner(alice);

        vm.expectRevert();

        vm.prank(bob);
        creatorMod.create(defaultValue, type(MockTarget).creationCode);
    }

    function testCreateFailingInitcode() public {
        setRunner(alice);

        vm.expectRevert();

        vm.prank(alice);
        creatorMod.create(defaultValue, failingInitcode);
    }

    function testCreate2() public {
        setRunner(alice);

        vm.deal(alice, defaultValue);

        vm.prank(alice);
        address deployment =
            creatorMod.create2{ value: defaultValue }(defaultSalt, defaultValue, type(MockTarget).creationCode);

        assertNotEq(deployment, address(0));
        assertEq(deployment, creatorMod.compute2(defaultSalt, type(MockTarget).creationCode));
        assertEq(deployment.codehash, address(new MockTarget()).codehash);
        assertEq(deployment.balance, defaultValue);
    }

    function testCreate2FromModBalance() public {
        setRunner(alice);

        vm.deal(address(creatorMod), defaultValue);

        vm.prank(alice);
        address deployment = creatorMod.create2(defaultSalt, defaultValue, type(MockTarget).creationCode);

        assertNotEq(deployment, address(0));
        assertEq(deployment, creatorMod.compute2(defaultSalt, type(MockTarget).creationCode));
        assertEq(deployment.codehash, address(new MockTarget()).codehash);
        assertEq(deployment.balance, defaultValue);
    }

    function testCreate2NoValue() public {
        setRunner(alice);

        vm.prank(alice);
        address deployment = creatorMod.create2(defaultSalt, 0, type(MockTarget).creationCode);

        assertNotEq(deployment, address(0));
        assertEq(deployment, creatorMod.compute2(defaultSalt, type(MockTarget).creationCode));
        assertEq(deployment.codehash, address(new MockTarget()).codehash);
        assertEq(deployment.balance, 0);
    }

    function testCreate2NotRunner() public {
        setRunner(alice);

        vm.expectRevert();

        vm.prank(bob);
        creatorMod.create2(defaultSalt, defaultValue, type(MockTarget).creationCode);
    }

    function testCreate2FailingInitcode() public {
        setRunner(alice);

        vm.expectRevert();

        vm.prank(alice);
        creatorMod.create2(defaultSalt, defaultValue, failingInitcode);
    }

    function testCompute2() public {
        address deployment = creatorMod.compute2(defaultSalt, type(MockTarget).creationCode);

        address expected = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff), address(creatorMod), defaultSalt, keccak256(type(MockTarget).creationCode)
                        )
                    )
                )
            )
        );

        assertEq(deployment, expected);
    }

    function testFuzzCreate(
        bool runnerIsActor,
        address runner,
        address actor,
        uint256 value,
        bool initcodeFails,
        bool valueFromMod
    ) public {
        runner = runnerIsActor ? actor : runner;

        setRunner(runner);

        if (valueFromMod) {
            vm.deal(address(creatorMod), value);
        } else {
            vm.deal(actor, value);
        }

        if (initcodeFails || runner != actor) {
            vm.expectRevert();
        }

        uint256 callvalue = valueFromMod ? 0 : value;
        bytes memory initcode = initcodeFails ? failingInitcode : type(MockTarget).creationCode;

        vm.prank(actor);
        address deployment = creatorMod.create{ value: callvalue }(value, initcode);

        if (!initcodeFails && runner == actor) {
            assertNotEq(deployment, address(0));
            assertEq(deployment.codehash, address(new MockTarget()).codehash);
            assertEq(deployment.balance, value);
        }
    }

    function testFuzzCreate2(
        bool runnerIsActor,
        address runner,
        address actor,
        bytes32 salt,
        uint256 value,
        bool initcodeFails,
        bool valueFromMod
    ) public {
        runner = runnerIsActor ? actor : runner;

        setRunner(runner);

        if (valueFromMod) {
            vm.deal(address(creatorMod), value);
        } else {
            vm.deal(actor, value);
        }

        if (initcodeFails || runner != actor) {
            vm.expectRevert();
        }

        uint256 callvalue = valueFromMod ? 0 : value;
        bytes memory initcode = initcodeFails ? failingInitcode : type(MockTarget).creationCode;

        vm.prank(actor);
        address deployment = creatorMod.create2{ value: callvalue }(salt, value, initcode);

        if (!initcodeFails && runner == actor) {
            assertNotEq(deployment, address(0));
            assertEq(deployment, creatorMod.compute2(salt, initcode));
            assertEq(deployment.codehash, address(new MockTarget()).codehash);
            assertEq(deployment.balance, value);
        }
    }

    function testFuzzCompute2(bytes32 salt, bytes memory initcode) public {
        address deployment = creatorMod.compute2(salt, initcode);

        address expected = address(
            uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(creatorMod), salt, keccak256(initcode)))))
        );

        assertEq(deployment, expected);
    }

    function setRunner(address runner) public {
        vm.store(address(creatorMod), bytes32(uint256(1)), bytes32(uint256(uint160(runner))));
    }
}
