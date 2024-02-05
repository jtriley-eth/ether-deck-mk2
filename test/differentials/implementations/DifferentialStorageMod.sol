// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

contract DifferentialStorageMod {
    mapping(bytes4 => address) internal dispatch;
    address internal runner;

    function write(bytes32[] calldata slots, bytes32[] calldata values) external {
        require(msg.sender == runner);
        require(slots.length == values.length);

        for (uint256 i; i < slots.length; i++) {
            bytes32 slot = slots[i];
            bytes32 value = values[i];
            assembly {
                sstore(slot, value)
            }
        }
    }

    function read(bytes32[] calldata slots) external view returns (bytes32[] memory values) {
        values = new bytes32[](slots.length);

        for (uint256 i; i < slots.length; i++) {
            bytes32 slot = slots[i];
            bytes32 value;
            assembly {
                value := sload(slot)
            }
            values[i] = value;
        }
    }
}
