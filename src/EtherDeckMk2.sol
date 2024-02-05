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

    constructor() {
        assembly {
            sstore(runner.slot, caller())
        }
    }

    /// @notice runs a call
    /// @dev directives:
    ///      01. check if caller is runner; cache as success
    ///      02. copy payload to memory
    ///      03. make external call to target with callvalue and payload; compose success
    ///      04. copy returndata to memory
    ///      05. if success, return with returndata
    ///      06. else, revert with revertdata
    /// @param target the call target
    /// @param payload the call payload
    function run(address target, bytes calldata payload) external payable {
        assembly {
            let success := eq(caller(), sload(runner.slot))

            calldatacopy(0x00, payload.offset, payload.length)

            success := and(success, call(gas(), target, callvalue(), 0x00, payload.length, 0x00, 0x00))

            returndatacopy(0x00, 0x00, returndatasize())

            if success { return(0x00, returndatasize()) }

            revert(0x00, returndatasize())
        }
    }

    /// @notice runs a batch of calls
    /// @dev directives:
    ///      01. check if caller is runner; cache as success
    ///      02. load target offset; cache as targetPtr
    ///      03. load value offset; cache as valuePtr
    ///      04. load payload offset; cache as payloadPtr
    ///      05. compute end of targets; cache as targetsEnd
    ///      06. check that targets and values length match; compose success
    ///      07. check that targets and payloads length match; compose success
    ///      08. loop:
    ///          a. if targetPtr is targetsEnd, break loop
    ///          b. compute payload offset; cache as payload
    ///          c. load payload length from calldata; cache as payloadLen
    ///          d. copy payload to memory
    ///          e. load target from calldata; cache as target
    ///          f. make external call to target with value and payload; cache as success
    ///          g. increment target offset
    ///          h. increment value offset
    ///          i. increment payload offset
    ///      09. if success, return
    ///      10. else, revert
    /// @param targets the call targets
    /// @param values the call values
    /// @param payloads the call payloads
    function runBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads
    ) external payable {
        assembly {
            let success := eq(caller(), sload(runner.slot))

            let targetPtr := targets.offset

            let valuePtr := values.offset

            let payloadPtr := payloads.offset

            let targetsEnd := add(targets.offset, mul(targets.length, 0x20))

            success := and(success, eq(targets.length, values.length))

            success := and(success, eq(targets.length, payloads.length))

            for { } 1 { } {
                if eq(targetPtr, targetsEnd) { break }

                let payload := add(payloads.offset, calldataload(payloadPtr))

                let payloadLen := calldataload(payload)

                calldatacopy(0x00, add(0x20, payload), payloadLen)

                let target := calldataload(targetPtr)

                success := and(success, call(gas(), target, calldataload(valuePtr), 0x00, payloadLen, 0x00, 0x00))

                targetPtr := add(targetPtr, 0x20)

                valuePtr := add(valuePtr, 0x20)

                payloadPtr := add(payloadPtr, 0x20)
            }

            if success { return(0x00, 0x00) }

            revert(0x00, 0x00)
        }
    }

    /// @notice sets the dispatcher of a selector to a target address
    /// @dev directives:
    ///      01. revert if caller is not runner
    ///      02. copy selector to memory
    ///      03. store target in storage at `dispatch[selector]`
    ///      04. log dispatch set
    /// @dev the address set by this has full write access over the ether deck
    /// @param selector the selector to dispatch from
    /// @param target the target address to dispatch to
    function setDispatch(bytes4 selector, address target) external {
        assembly {
            if iszero(eq(caller(), sload(runner.slot))) { revert(0x00, 0x00) }

            mstore(0x00, selector)

            sstore(keccak256(0x00, 0x40), target)

            log3(0x00, 0x00, 0x2c0b629fc2b386c229783b88b245e8730c1397b78e4dd4a43cd7aafdf1b39f12, selector, target)
        }
    }

    /// @notice sets the dispatcher of an array of selector to target addresses
    /// @dev directives:
    ///      01. check if caller is runner; cache as success
    ///      02. check success and that selectors and targets length match, revert if not
    ///      03. load selector offset; cache as selectorPtr
    ///      04. load target offset; cache as targetPtr
    ///      05. compute end of selectors; cache as selectorsEnd
    ///      06. loop:
    ///          a. if selectorPtr is selectorsEnd, break loop
    ///          b. load selector from calldata; cache as selector
    ///          c. load target from calldata; cache as target
    ///          d. store selector in memory
    ///          e. store target in storage at `dispatch[selector]`
    ///          f. log dispatch set
    ///          g. increment selector offset
    ///          h. increment target offset
    function setDispatchBatch(bytes4[] calldata selectors, address[] calldata targets) external {
        assembly {
            let success := eq(caller(), sload(runner.slot))

            if iszero(and(success, eq(selectors.length, targets.length))) { revert(0x00, 0x00) }

            let selectorPtr := selectors.offset

            let targetPtr := targets.offset

            let selectorsEnd := add(selectors.offset, mul(selectors.length, 0x20))

            success := and(success, eq(selectors.length, targets.length))

            for { } 1 { } {
                if eq(selectorPtr, selectorsEnd) { break }

                let selector := calldataload(selectorPtr)

                let target := calldataload(targetPtr)

                mstore(0x00, selector)

                sstore(keccak256(0x00, 0x40), target)

                log3(0x00, 0x00, 0x2c0b629fc2b386c229783b88b245e8730c1397b78e4dd4a43cd7aafdf1b39f12, selector, target)

                selectorPtr := add(selectorPtr, 0x20)

                targetPtr := add(targetPtr, 0x20)
            }
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
