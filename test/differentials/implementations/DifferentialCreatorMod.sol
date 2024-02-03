// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

contract DifferentialCreatorMod {
    mapping(bytes4 => address) internal dispatch;
    address internal runner;
    uint256 internal nonce;

    function create(uint256 value, bytes memory initcode) external payable returns (address deployment) {
        require(msg.sender == runner);
        assembly {
            deployment := create(value, add(initcode, 0x20), mload(initcode))
        }
        require(deployment != address(0));
    }

    function create2(
        bytes32 salt,
        uint256 value,
        bytes memory initcode
    ) external payable returns (address deployment) {
        require(msg.sender == runner);
        assembly {
            deployment := create2(value, add(initcode, 0x20), mload(initcode), salt)
        }
        require(deployment != address(0));
    }

    function compute2(bytes32 salt, bytes memory initcode) external view returns (address deployment) {
        return address(
            uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(initcode)))))
        );
    }
}
