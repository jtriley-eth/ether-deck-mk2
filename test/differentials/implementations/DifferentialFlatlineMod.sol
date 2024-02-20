// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

contract DifferentialFlatlineMod {
    mapping(bytes4 => address) internal dispatch;
    address internal runner;

    function setContingency(address receiver, uint32 interval) public {
        require(msg.sender == runner);
        uint256 slot = flatlineSlot();
        uint256 value = pack(receiver, interval, uint64(block.timestamp));
        assembly {
            sstore(slot, value)
        }
    }

    function checkIn() public {
        require(msg.sender == runner);
        uint256 slot = flatlineSlot();
        uint256 value;

        assembly {
            value := sload(slot)
        }

        (address receiver, uint32 interval,) = unpack(value);
        value = pack(receiver, interval, uint64(block.timestamp));

        assembly {
            sstore(slot, value)
        }
    }

    function contingency() public {
        uint256 slot = flatlineSlot();
        uint256 value;

        assembly {
            value := sload(slot)
        }

        (address receiver, uint32 interval, uint64 timestamp) = unpack(value);

        require(interval != 0 && block.timestamp >= timestamp + interval);

        runner = receiver;
        value = 0;

        assembly {
            sstore(slot, value)
        }
    }

    function flatlineSlot() internal pure returns (uint256) {
        return uint256(keccak256("EtherDeckMk2.Flatline.contingency")) - 1;
    }

    function pack(address receiver, uint32 interval, uint64 timestamp) internal pure returns (uint256) {
        return uint256(uint160(receiver)) << 96 | uint256(interval) << 64 | uint256(timestamp);
    }

    function unpack(uint256 value) internal pure returns (address receiver, uint32 interval, uint64 timestamp) {
        receiver = address(uint160(value >> 96));
        interval = uint32(value >> 64);
        timestamp = uint64(value);
    }
}
