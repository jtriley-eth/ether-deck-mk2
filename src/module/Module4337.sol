// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

struct Op4337 {
    address sender;
    uint256 nonce;
    bytes initCode;
    bytes callData;
    bytes32 accountGasLimits;
    uint256 preVerificationGas;
    uint256 maxFeePerGas;
    uint256 maxPriorityFeePerGas;
    bytes paymasterAndData;
    bytes signature;
}

/// @title Ether Deck Mk2 ERC-4337 User Operation Validation Module
/// @author jtriley.eth
/// @notice implements erc-4337 account interface
contract Module4337 {
    mapping(bytes4 => address) internal dispatch;
    address internal runner;
    uint256 internal nonce;

    /// @notice sets the entry point for user operations
    /// @dev Directives:
    ///      01. if caller is not runner, revert
    ///      02. store entry point in storage
    /// @param entryPoint the address of the entry point
    function setEntryPoint(address entryPoint) external {
        assembly {
            if iszero(eq(sload(runner.slot), caller())) { revert(0x00, 0x00) }

            sstore(0xeeadf9c47495dc7413664b6a976e5956125db2f78ef26b808660c128f443d4ab, entryPoint)
        }
    }

    /// @notice validates user operation of erc-4337
    /// @dev Directives:
    ///      01. load entry point from storage
    ///      02. if caller is not entry point, revert
    ///      03. store op hash in memory
    ///      04. copy op signature to memory
    ///      05. run ecrecover; discard success boolean
    ///      06. check if ecrecover result is runner, flip boolean, store validationData in memory
    ///      07. if funding is nonzero, send funding to entry point
    ///      08. return validationData
    /// @dev validation data is defined as packed `isInvalid_u160 . validUntil_u48 . validAfter_u48`
    /// @dev we set validUntil and validAfter as zero to indicate the op is valid indefinitely
    /// @param opHash the hash of the user operation
    /// @param funding the amount of funding to send to the entry point
    /// @return validationData the validation data
    function validateUserOp(Op4337 calldata, bytes32 opHash, uint256 funding) external returns (uint256) {
        assembly {
            let entryPoint := sload(0xeeadf9c47495dc7413664b6a976e5956125db2f78ef26b808660c128f443d4ab)

            if iszero(eq(caller(), entryPoint)) { revert(0x00, 0x00) }

            mstore(0x00, opHash)

            calldatacopy(0x20, add(0x20, calldataload(0x184)), 0x60)

            pop(staticcall(gas(), 0x01, 0x00, 0x80, 0x00, 0x20))

            mstore(0x00, shl(0x60, iszero(eq(mload(0x00), sload(runner.slot)))))

            if funding { pop(call(gas(), caller(), funding, 0x00, 0x00, 0x00, 0x00)) }

            return(0x00, 0x20)
        }
    }
}
