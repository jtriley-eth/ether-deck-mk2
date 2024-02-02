// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import { Test } from "../../lib/forge-std/src/Test.sol";

import { CreatorMod } from "../../src/mods/CreatorMod.sol";
import { DifferentialCreatorMod } from "./implementations/DifferentialCreatorMod.sol";
import { MockTarget } from "../mock/MockTarget.sol";

contract DifferentialCreatorModTest is Test {
    CreatorMod internal fastCreatorMod;
    DifferentialCreatorMod internal slowCreatorMod;

    bytes internal constant failingInitcode = hex"5f5ffd";

    function setUp() public {
        fastCreatorMod = new CreatorMod();
        slowCreatorMod = new DifferentialCreatorMod();
    }

    function testFuzzDiffCreate(
        bool runnerIsActor,
        address runner,
        address actor,
        uint256 value,
        bool initcodeFails,
        bool valueFromMod
    ) public {
        value = bound(value, 0, type(uint256).max / 2);
        runner = runnerIsActor ? actor : runner;

        setRunner(runner);

        if (valueFromMod) {
            vm.deal(address(fastCreatorMod), value);
            vm.deal(address(slowCreatorMod), value);
        } else {
            vm.deal(runner, value * 2);
        }

        uint256 callvalue = valueFromMod ? 0 : value;
        bytes memory initcode = initcodeFails ? failingInitcode : type(MockTarget).creationCode;

        vm.startPrank(actor);
        if (initcodeFails || runner != actor) {
            vm.expectRevert();
            fastCreatorMod.create{ value: callvalue }(value, initcode);

            vm.expectRevert();
            slowCreatorMod.create{ value: callvalue }(value, initcode);
        } else {
            address fastDeployment = fastCreatorMod.create{ value: callvalue }(value, initcode);

            address slowDeployment = slowCreatorMod.create{ value: callvalue }(value, initcode);

            assertNotEq(fastDeployment, address(0));
            assertNotEq(slowDeployment, address(0));
            assertEq(fastDeployment.codehash, slowDeployment.codehash);
            assertEq(fastDeployment.balance, slowDeployment.balance);
            assertEq(fastDeployment.balance, value);
        }

        vm.stopPrank();
    }

    function testFuzzDiffCreate2(
        bool runnerIsActor,
        address runner,
        address actor,
        bytes32 salt,
        uint256 value,
        bool initcodeFails,
        bool valueFromMod
    ) public {
        value = bound(value, 0, type(uint256).max / 2);
        runner = runnerIsActor ? actor : runner;

        setRunner(runner);

        if (valueFromMod) {
            vm.deal(address(fastCreatorMod), value);
            vm.deal(address(slowCreatorMod), value);
        } else {
            vm.deal(runner, value * 2);
        }

        uint256 callvalue = valueFromMod ? 0 : value;
        bytes memory initcode = initcodeFails ? failingInitcode : type(MockTarget).creationCode;

        vm.startPrank(actor);
        if (initcodeFails || runner != actor) {
            vm.expectRevert();
            fastCreatorMod.create2{ value: callvalue }(salt, value, initcode);

            vm.expectRevert();
            slowCreatorMod.create2{ value: callvalue }(salt, value, initcode);
        } else {
            address fastDeployment = fastCreatorMod.create2{ value: callvalue }(salt, value, initcode);

            address slowDeployment = slowCreatorMod.create2{ value: callvalue }(salt, value, initcode);

            assertNotEq(fastDeployment, address(0));
            assertNotEq(slowDeployment, address(0));
            assertEq(fastDeployment.codehash, slowDeployment.codehash);
            assertEq(fastDeployment.balance, slowDeployment.balance);
            assertEq(fastDeployment.balance, value);
        }

        vm.stopPrank();
    }

    function testFuzzDiffCompute2(address sourceAddress, bytes32 salt, bytes memory initcode) public {
        if (
            sourceAddress == address(vm) || sourceAddress == address(0x000000000000000000636F6e736F6c652e6c6f67)
                || uint160(sourceAddress) < 256
        ) {
            sourceAddress = address(uint160(sourceAddress) + 256);
        }
        vm.assume(sourceAddress != address(fastCreatorMod) && sourceAddress != address(slowCreatorMod));

        vm.etch(sourceAddress, address(fastCreatorMod).code);
        address fastDeployment = CreatorMod(sourceAddress).compute2(salt, initcode);

        vm.etch(sourceAddress, address(slowCreatorMod).code);
        address slowDeployment = DifferentialCreatorMod(sourceAddress).compute2(salt, initcode);

        assertEq(fastDeployment, slowDeployment);
    }

    function setRunner(address runner) public {
        vm.store(address(fastCreatorMod), bytes32(uint256(1)), bytes32(uint256(uint160(runner))));
        vm.store(address(slowCreatorMod), bytes32(uint256(1)), bytes32(uint256(uint160(runner))));
    }
}
