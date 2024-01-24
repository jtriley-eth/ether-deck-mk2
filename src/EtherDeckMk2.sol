// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

/// @title Ether Deck Mk2
/// @author jtriley.eth
/// @notice a reasonably optimized smart account
contract EtherDeckMk2 {
    /// @notice logged on dispatch set
    /// @param selector the selector dispatched from
    /// @param target the target address dispatched to
    event DispatchSet(bytes4 indexed selector, address indexed target);

    /// @notice dispatcher of selectors to target addresses
    /// @dev occupies slot 0 for `fallback` memory optimization; if you inherit it, it must be
    ///      inherited first or you must add an additional memory write
    mapping(bytes4 => address) public dispatch;

    /// @notice runner of calls
    address public runner;

    /// @notice nonce of runner
    uint256 public nonce;

    /// @notice runs a call
    /// @dev Directives:
    ///      01. check if caller is runner; cache as success
    ///      02. copy payload to memory
    ///      02. make external call to target with callvalue and payload; compose success
    ///      03. copy returndata to memory
    ///      04. if success, return with returndata
    ///      05. else, revert with revertdata
    /// @param target the call target
    /// @param payload the call payload
    function run(address target, bytes calldata payload) external payable {
        assembly {
            let success := eq(sload(runner.slot), caller())

            calldatacopy(0x00, payload.offset, payload.length)

            success := and(success, call(gas(), target, callvalue(), 0x00, payload.length, 0x00, 0x00))

            returndatacopy(0x00, 0x00, returndatasize())

            if success { return(0x00, returndatasize()) }

            revert(0x00, returndatasize())
        }
    }

    /// @notice runs a batch of calls
    /// @dev Directives:
    ///      01. check if caller is runner; cache as success
    ///      02. load target offset; cache as targetOffset
    ///      03. load value offset; cache as valueOffset
    ///      04. load payload offset; cache as payloadOffset
    ///      05. check that targets and values length match; compose success
    ///      06. check that targets and payloads length match; compose success
    ///      07. loop:
    ///          a. load target from calldata
    ///          b. if target is zero, break loop
    ///          c. load payload length from calldata; cache as paylaodLength
    ///          d. copy payload to memory
    ///          e. make external call to target with value and payload; cache as success
    ///          f. increment target offset
    ///          g. increment value offset
    ///          h. increment payload offset
    ///      08. if success, return
    ///      09. else, revert
    /// @param targets the call targets
    /// @param values the call values
    /// @param payloads the call payloads
    function runBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads
    ) external payable {
        assembly {
            let success := eq(sload(runner.slot), caller())

            let targetOffset := targets.offset

            let valueOffset := values.offset

            let payloadOffset := add(0x20, payloads.offset)

            success := and(success, eq(targets.length, values.length))

            success := and(success, eq(targets.length, payloads.length))

            for { } 1 { } {
                let target := calldataload(targetOffset)

                if iszero(target) { break }

                let payloadLength := mload(payloadOffset)

                calldatacopy(0x00, add(0x20, payloadOffset), payloadLength)

                success := and(success, call(gas(), target, calldataload(valueOffset), 0x00, payloadLength, 0x00, 0x00))

                targetOffset := add(targetOffset, 0x20)

                valueOffset := add(valueOffset, 0x20)

                payloadOffset := add(payloadOffset, add(0x20, payloadLength))
            }

            if success { return(0x00, 0x00) }

            revert(0x00, 0x00)
        }
    }

    /// @notice runs a call on behalf of the runner
    /// @dev directives:
    ///      01. subtract bribe from callvalue; cache as value
    ///      01. copy sigdata to memory
    ///      02. ecrecover; cache as success
    ///      03. check if recovered address is runner; compose success
    ///      04. copy payload to memory
    ///      00. compute payload end; cache as payloadEnd
    ///      05. store target after payload in memory
    ///      00. store value after target in memory
    ///      00. store bribe after value in memory
    ///      06. load nonce from storage; cache as sigNonce
    ///      07. store nonce after payload, target, value, and bribe in memory
    ///      08. check if hash matches sigdata hash; compose success
    ///      09. store incremented nonce in storage
    ///      00. make external call to caller with bribe; compose success
    ///      10. make external call to target with value and payload; compose success
    ///      11. copy returndata to memory
    ///      12. if success, return with returndata
    ///      13. else, revert with revertdata
    /// @dev sighash is `keccak256(abi.encode(payload, target, value, bribe, nonce))`
    /// @param target the call target address
    /// @param payload the call payload
    /// @param sigdata the ecrecover signature data
    function runFrom(address target, bytes calldata payload, bytes calldata sigdata, uint256 bribe) external payable {
        assembly {
            let value := sub(callvalue(), bribe)

            calldatacopy(0x00, sigdata.offset, sigdata.length)

            let success := staticcall(gas(), 0x01, 0x00, sigdata.length, 0x00, 0x20)

            success := and(success, eq(mload(0x00), sload(runner.slot)))

            calldatacopy(0x00, payload.offset, payload.length)

            let payloadEnd := add(payload.offset, payload.length)

            mstore(payloadEnd, target)

            mstore(add(0x20, payloadEnd), value)

            mstore(add(0x40, payloadEnd), bribe)

            let sigNonce := sload(nonce.slot)

            mstore(add(0x60, payloadEnd), sigNonce)

            success := and(success, eq(keccak256(0x00, add(0x80, payload.length)), calldataload(sigdata.offset)))

            sstore(nonce.slot, add(sigNonce, 0x01))

            success := and(success, call(gas(), caller(), bribe, 0x00, 0x00, 0x00, 0x00))

            success := and(success, call(gas(), target, callvalue(), 0x00, payload.length, 0x00, 0x00))

            returndatacopy(0x00, 0x00, returndatasize())

            if success { return(0x00, returndatasize()) }

            revert(0x00, returndatasize())
        }
    }

    /// @notice sets the dispatcher of a selector to a target address
    /// @dev Directives:
    ///      01. revert if caller is not runner
    ///      02. copy selector to memory
    ///      03. store target in storage at `dispatch[selector]`
    ///      04. log dispatch set
    /// @dev the address set by this has full write access over the ether deck
    /// @param selector the selector to dispatch from
    /// @param target the target address to dispatch to
    function setDispatch(bytes4 selector, address target) external {
        assembly {
            if iszero(eq(sload(runner.slot), caller())) { revert(0x00, 0x00) }

            mstore(0x00, selector)

            sstore(keccak256(0x00, 0x40), target)

            log3(0x00, 0x00, 0x66e3803c874b81b53665affdd2cf10254cd6c0c36f33813634442a0844621bf9, selector, target)
        }
    }

    /// @notice receives data from arbitrary context
    /// @dev directives:
    ///      01. moves selector from calldata to memory
    ///      02. loads `dispatch[selector]` from storage; cache as target
    ///      03. if target is unassigned, return selector
    ///      04. copy calldata to memory
    ///      05. make external call to target with callvalue and calldata; cache as success
    ///      06. copy returndata to memory
    ///      07. if success, return with returndata
    ///      08. else, revert with revertdata
    /// @dev default behavior for unassigned selectors is to return the selector for compliance with
    ///      erc standards that impose undue constraints on receivers.
    fallback() external payable {
        assembly {
            mstore(0x00, shl(0xe0, shr(0xe0, calldataload(0x00))))

            let target := sload(keccak256(0x00, 0x40))

            if iszero(target) { return(0x00, 0x20) }

            calldatacopy(0x00, 0x00, calldatasize())

            let success := delegatecall(gas(), target, 0x00, calldatasize(), 0x00, 0x00)

            returndatacopy(0x00, 0x00, returndatasize())

            if success { return(0x00, returndatasize()) }

            revert(0x00, returndatasize())
        }
    }

    receive() external payable { }
}
