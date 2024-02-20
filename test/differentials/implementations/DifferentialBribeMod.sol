// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

contract DifferentialBribeMod {
    mapping(bytes4 => address) internal dispatch;
    address internal runner;

    function nonce() public view returns (uint256 value) {
        uint256 slot = uint256(keccak256("EtherDeckMk2.BribeMod.nonce")) - 1;
        assembly {
            value := sload(slot)
        }
    }

    function bribeBuilder(address target, bytes calldata payload, uint256 bribe) external payable {
        require(msg.sender == runner);

        (bool success, bytes memory returndata) = target.call{ value: msg.value }(payload);
        require(success);

        (success,) = block.coinbase.call{ value: bribe }("");
        require(success);

        assembly {
            return(add(0x20, returndata), mload(returndata))
        }
    }

    function bribeCaller(
        address target,
        bytes calldata payload,
        bytes calldata sigdata,
        uint256 bribe
    ) external payable {
        (bytes32 hash, uint8 v, bytes32 r, bytes32 s) = abi.decode(sigdata, (bytes32, uint8, bytes32, bytes32));
        uint256 sigNonce = nonce();

        require(hash == keccak256(abi.encodePacked(payload, uint256(uint160(target)), msg.value, bribe, sigNonce)));
        require(runner == ecrecover(hash, v, r, s));

        uint256 nonceSlot = uint256(keccak256("EtherDeckMk2.BribeMod.nonce")) - 1;
        sigNonce += 1;
        assembly {
            sstore(nonceSlot, sigNonce)
        }

        (bool success, bytes memory retdata) = target.call{ value: msg.value }(payload);
        (bool bribeSuccess,) = msg.sender.call{ value: bribe }("");

        if (success && bribeSuccess) {
            assembly {
                return(add(0x20, retdata), mload(retdata))
            }
        } else {
            assembly {
                revert(add(0x20, retdata), mload(retdata))
            }
        }
    }
}
