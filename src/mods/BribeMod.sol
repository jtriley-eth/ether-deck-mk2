// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

/// @title Ether Deck Mk2 Flash Mod
/// @author jtriley.eth
/// @notice a reasonably optimized bribe mod for Ether Deck Mk2
contract BribeMod {
    mapping(bytes4 => address) internal dispatch;
    address internal runner;

    /// @notice returns the nonce of the runner
    /// @dev directives:
    ///      01. move nonce from storage to memory
    ///      02. return nonce
    /// @dev the nonce slot is defined as `keccak256("EtherDeckMk2.Nonce") - 1`
    /// @return nonce the nonce of the runner
    function nonce() external view returns (uint256) {
        assembly {
            mstore(0x00, sload(0x51448ae5f8e845d125c02858a227e28c25f218a7e0050dff756ebd4ae4439c98))

            return(0x00, 0x20)
        }
    }

    /// @notice bribes the block builder to run with zero gas value
    /// @dev directives:
    ///      01. check if caller is runner; cache as success
    ///      02. copy payload to memory
    ///      03. make external call to coinbase with bribe; compose success
    ///      04. make external call to target with callvalue and payload; compose success
    ///      05. copy returndata to memory
    ///      06. if success, return with returndata
    ///      07. else, revert with revertdata
    /// @param target the call target address
    /// @param payload the call payload
    function bribeBuilder(address target, bytes calldata payload, uint256 bribe) external payable {
        assembly {
            let success := eq(caller(), sload(runner.slot))

            calldatacopy(0x00, payload.offset, payload.length)

            success := and(success, call(gas(), coinbase(), bribe, 0x00, 0x00, 0x00, 0x00))

            success := and(success, call(gas(), target, callvalue(), 0x00, payload.length, 0x00, 0x00))

            returndatacopy(0x00, 0x00, returndatasize())

            if success { return(0x00, returndatasize()) }

            revert(0x00, returndatasize())
        }
    }

    /// @notice bribes the caller to run on behalf of the runner
    /// @dev directives:
    ///      01. copy sigdata to memory
    ///      02. ecrecover; cache as success
    ///      03. check if recovered address is runner; compose success
    ///      04. copy payload to memory
    ///      05. store target after payload in memory
    ///      06. store callvalue after target in memory
    ///      07. store bribe after callvalue in memory
    ///      08. load nonce from storage; cache as nonce
    ///      09. store nonce after payload, target, callvalue, and bribe in memory
    ///      10. check if hash matches sigdata hash; compose success
    ///      11. store incremented nonce in storage
    ///      12. make external call to caller with bribe; compose success
    ///      13. make external call to target with callvalue and payload; compose success
    ///      14. copy returndata to memory
    ///      15. if success, return with returndata
    ///      16. else, revert with revertdata
    /// @dev sighash is `keccak256(abi.encode(payload, target, callvalue, bribe, nonce))`
    /// @dev the nonce slot is defined as `keccak256("EtherDeckMk2.Nonce") - 1`
    /// @param target the call target address
    /// @param payload the call payload
    /// @param sigdata the ecrecover signature data
    function bribeCaller(
        address target,
        bytes calldata payload,
        bytes calldata sigdata,
        uint256 bribe
    ) external payable {
        assembly {
            calldatacopy(0x00, sigdata.offset, sigdata.length)

            let success := staticcall(gas(), 0x01, 0x00, sigdata.length, 0x00, 0x20)

            success := and(success, eq(mload(0x00), sload(runner.slot)))

            calldatacopy(0x00, payload.offset, payload.length)

            mstore(payload.length, target)

            mstore(add(0x20, payload.length), callvalue())

            mstore(add(0x40, payload.length), bribe)

            let nonce := sload(0x51448ae5f8e845d125c02858a227e28c25f218a7e0050dff756ebd4ae4439c98)

            mstore(add(0x60, payload.length), nonce)

            success := and(success, eq(keccak256(0x00, add(0x80, payload.length)), calldataload(sigdata.offset)))

            sstore(0x51448ae5f8e845d125c02858a227e28c25f218a7e0050dff756ebd4ae4439c98, add(nonce, 0x01))

            success := and(success, call(gas(), caller(), bribe, 0x00, 0x00, 0x00, 0x00))

            success := and(success, call(gas(), target, callvalue(), 0x00, payload.length, 0x00, 0x00))

            returndatacopy(0x00, 0x00, returndatasize())

            if success { return(0x00, returndatasize()) }

            revert(0x00, returndatasize())
        }
    }
}
