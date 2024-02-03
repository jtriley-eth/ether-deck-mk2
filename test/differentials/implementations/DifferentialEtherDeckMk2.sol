// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

contract DifferentialEtherDeckMk2 {
    event DispatchSet(bytes4 indexed selector, address indexed target);

    mapping(bytes4 => address) public dispatch;
    address public runner;
    uint256 public nonce;

    function run(address target, bytes calldata payload) external payable {
        require(runner == msg.sender);
        (bool success, bytes memory returndata) = target.call{ value: msg.value }(payload);
        if (success) {
            assembly {
                return(add(0x20, returndata), mload(returndata))
            }
        } else {
            assembly {
                revert(add(0x20, returndata), mload(returndata))
            }
        }
    }

    function runBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads
    ) external payable {
        require(runner == msg.sender);
        require(targets.length == values.length);
        require(targets.length == payloads.length);
        for (uint256 i; i < targets.length; i++) {
            (bool success,) = targets[i].call{ value: values[i] }(payloads[i]);
            require(success);
        }
    }

    function runFrom(address target, bytes calldata payload, bytes calldata sigdata, uint256 bribe) external payable {
        (bytes32 hash, uint8 v, bytes32 r, bytes32 s) = abi.decode(sigdata, (bytes32, uint8, bytes32, bytes32));

        require(hash == keccak256(abi.encodePacked(payload, uint256(uint160(target)), msg.value, bribe, nonce)));
        require(runner == ecrecover(hash, v, r, s));

        nonce++;

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

    function setDispatch(bytes4 selector, address target) external {
        require(msg.sender == runner);
        dispatch[selector] = target;
        emit DispatchSet(selector, target);
    }

    fallback() external payable {
        bytes4 selector = msg.sig;

        address mod = dispatch[selector];

        if (mod == address(0)) {
            assembly {
                mstore(0x00, selector)
                return(0x00, 0x20)
            }
        }

        (bool success, bytes memory retdata) = mod.delegatecall(msg.data);

        if (success) {
            assembly {
                return(add(0x20, retdata), mload(retdata))
            }
        } else {
            assembly {
                revert(add(0x20, retdata), mload(retdata))
            }
        }
    }

    receive() external payable { }
}
