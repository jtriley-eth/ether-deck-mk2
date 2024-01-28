// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

/// @title Ether Deck Mk2 Mass Revoke Mod
/// @author jtriley.eth
/// @notice a reasonably optimized approval revocation mod for Ether Deck Mk2
/// @dev supports erc-20, erc-721, erc-1155, and erc-6909
contract MassRevokeMod {
    mapping(bytes4 => address) internal dispatch;
    address internal runner;
    uint256 internal nonce;

    /// @notice revokes approvals for erc-20 tokens
    /// @dev Directives:
    ///      01. check if caller is runner; cache as success
    ///      02. check if tokens and spenders are equal length; compose success
    ///      03. load token offset; cache as tokenOffset
    ///      04. load spender offset; cache as spenderOffset
    ///      05. store `erc20.approve.selector` in memory
    ///      06. store approve boolean in memory
    ///      07. loop:
    ///          a. load token from calldata
    ///          b. if token is zero, break loop
    ///          c. move spender from calldata to memory
    ///          d. call `erc20.approve`; compose success
    ///          e. check that the return value is either true or nothing; compose success
    ///          f. increment tokenOffset
    ///          g. increment spenderOffset
    ///      08. if success, return
    ///      09. else, revert
    /// @param tokens the tokens to revoke approval for
    /// @param spenders the spenders to revoke approval for
    function revokeERC20Approval(address[] calldata tokens, address[] calldata spenders) external {
        assembly {
            let success := eq(caller(), sload(runner.slot))

            success := and(success, eq(tokens.length, spenders.length))

            let tokenOffset := tokens.offset

            let spenderOffset := spenders.offset

            mstore(0x00, 0x095ea7b300000000000000000000000000000000000000000000000000000000)

            mstore(0x24, 0x00)

            for { } 1 { } {
                let token := calldataload(tokenOffset)

                if iszero(token) { break }

                mstore(0x04, calldataload(spenderOffset))

                success := and(success, call(gas(), token, 0x00, 0x00, 0x44, 0x44, 0x20))

                success := and(success, or(iszero(returndatasize()), mload(0x44)))

                tokenOffset := add(tokenOffset, 0x20)

                spenderOffset := add(spenderOffset, 0x20)
            }

            if success { return(0x00, 0x00) }

            revert(0x00, 0x00)
        }
    }

    /// @notice revokes approvals for erc-721 tokens
    /// @dev Directives:
    ///      01. check if caller is runner; cache as success
    ///      02. check if tokens and ids are equal length; compose success
    ///      03. load token offset; cache as tokenOffset
    ///      04. load id offset; cache as idOffset
    ///      05. store `erc721.approve.selector` in memory
    ///      06. loop:
    ///          a. load token from calldata
    ///          b. if token is zero, break loop
    ///          c. move id from calldata to memory
    ///          d. call `erc721.approve`; compose success
    ///          e. increment tokenOffset
    ///          f. increment idOffset
    ///      07. if success, return
    ///      08. else, revert
    /// @dev erc721.approve `_approved` argument is implicitly zero at memory[0x04]
    /// @param tokens the tokens to revoke approval for
    /// @param ids the ids to revoke approval for
    function revokeERC721Approval(address[] calldata tokens, uint256[] calldata ids) external {
        assembly {
            let success := eq(caller(), sload(runner.slot))

            success := and(success, eq(tokens.length, ids.length))

            let tokenOffset := tokens.offset

            let idOffset := ids.offset

            mstore(0x00, 0x095ea7b300000000000000000000000000000000000000000000000000000000)

            for { } 1 { } {
                let token := calldataload(tokenOffset)

                if iszero(token) { break }

                mstore(0x24, mload(idOffset))

                success := and(success, call(gas(), token, 0x00, 0x00, 0x44, 0x00, 0x00))

                tokenOffset := add(tokenOffset, 0x20)

                idOffset := add(idOffset, 0x20)
            }

            if success { return(0x00, 0x00) }

            revert(0x00, 0x00)
        }
    }

    /// @notice revokes approvals for erc-6909 tokens
    /// @dev Directives:
    ///      01. check if caller is runner; cache as success
    ///      02. check if tokens and ids are equal length; compose success
    ///      03. check if tokens and operators are equal length; compose success
    ///      04. load token offset; cache as tokenOffset
    ///      05. load id offset; cache as idOffset
    ///      06. load operator offset; cache as operatorOffset
    ///      07. store `erc6909.approve.selector` in memory
    ///      08. store approve boolean in memory
    ///      09. loop:
    ///          a. load token from calldata
    ///          b. if token is zero, break loop
    ///          c. move id from calldata to memory
    ///          d. move operator from calldata to memory
    ///          e. call `erc6909.approve`; compose success
    ///          f. check that the return value is true; compose success
    ///          g. increment tokenOffset
    ///          h. increment idOffset
    ///          i. increment operatorOffset
    ///      10. if success, return
    ///      11. else, revert
    /// @param tokens the tokens to revoke approval for
    /// @param ids the ids to revoke approval for
    /// @param operators the operators to revoke approval for
    function revokeERC6909Approval(
        address[] calldata tokens,
        uint256[] calldata ids,
        address[] calldata operators
    ) external {
        assembly {
            let success := eq(caller(), sload(runner.slot))

            success := and(success, eq(tokens.length, ids.length))

            success := and(success, eq(tokens.length, operators.length))

            let tokenOffset := tokens.offset

            let idOffset := ids.offset

            let operatorOffset := operators.offset

            mstore(0x00, 0x426a849300000000000000000000000000000000000000000000000000000000)

            mstore(0x44, 0x00)

            for { } 1 { } {
                let token := calldataload(tokenOffset)

                if iszero(token) { break }

                mstore(0x04, calldataload(idOffset))

                mstore(0x24, calldataload(operatorOffset))

                success := and(success, call(gas(), token, 0x00, 0x00, 0x64, 0x64, 0x20))

                success := and(success, mload(0x64))

                tokenOffset := add(tokenOffset, 0x20)

                idOffset := add(idOffset, 0x20)

                operatorOffset := add(operatorOffset, 0x20)
            }

            if success { return(0x00, 0x00) }

            revert(0x00, 0x00)
        }
    }

    /// @notice revokes operator approvals for erc-721 and erc-1155 tokens
    /// @dev Directives:
    ///      01. check if caller is runner; cache as success
    ///      02. check if tokens and operators are equal length; compose success
    ///      03. load token offset; cache as tokenOffset
    ///      04. load operator offset; cache as operatorOffset
    ///      05. store `{erc721, erc1155}.setApprovalForAll.selector` in memory
    ///      06. store approve boolean in memory
    ///      07. loop:
    ///          a. load token from calldata
    ///          b. if token is zero, break loop
    ///          c. move operator from calldata to memory
    ///          d. call `{erc721, erc1155}.setApprovalForAll`; compose success
    ///          e. increment tokenOffset
    ///          f. increment operatorOffset
    ///      08. if success, return
    ///      09. else, revert
    /// @param tokens the tokens to revoke approval for
    /// @param operators the operators to revoke approval for
    function revokeApprovalForAll(address[] calldata tokens, address[] calldata operators) external {
        assembly {
            let success := eq(caller(), sload(runner.slot))

            success := and(success, eq(tokens.length, operators.length))

            let tokenOffset := tokens.offset

            let operatorOffset := operators.offset

            mstore(0x00, 0xa22cb46500000000000000000000000000000000000000000000000000000000)

            mstore(0x44, 0x00)

            for { } 1 { } {
                let token := calldataload(tokenOffset)

                if iszero(token) { break }

                mstore(0x04, calldataload(operatorOffset))

                success := and(success, call(gas(), token, 0x00, 0x00, 0x64, 0x00, 0x00))

                tokenOffset := add(tokenOffset, 0x20)

                operatorOffset := add(operatorOffset, 0x20)
            }

            if success { return(0x00, 0x00) }

            revert(0x00, 0x00)
        }
    }

    /// @notice revokes operator approvals for erc-6909 tokens
    /// @dev Directives:
    ///      01. check if caller is runner; cache as success
    ///      02. check if tokens and operators are equal length; compose success
    ///      03. load token offset; cache as tokenOffset
    ///      04. load operator offset; cache as operatorOffset
    ///      05. store `erc6909.setOperator.selector` in memory
    ///      06. loop:
    ///          a. load token from calldata
    ///          b. if token is zero, break loop
    ///          c. move operator from calldata to memory
    ///          d. call `erc6909.setOperator`; compose success
    ///          e. check that the return value is true; compose success
    ///          f. increment tokenOffset
    ///          g. increment operatorOffset
    ///      07. if success, return
    ///      08. else, revert
    function revokeOperator(address[] calldata tokens, address[] calldata operators) external {
        assembly {
            let success := eq(caller(), sload(runner.slot))

            success := and(success, eq(tokens.length, operators.length))

            let tokenOffset := tokens.offset

            let operatorOffset := operators.offset

            mstore(0x00, 0x558a729700000000000000000000000000000000000000000000000000000000)

            mstore(0x24, 0x00)

            for { } 1 { } {
                let token := calldataload(tokenOffset)

                if iszero(token) { break }

                mstore(0x04, calldataload(operatorOffset))

                success := and(success, call(gas(), token, 0x00, 0x00, 0x44, 0x44, 0x20))

                success := and(success, mload(0x44))

                tokenOffset := add(tokenOffset, 0x20)

                operatorOffset := add(operatorOffset, 0x20)
            }

            if success { return(0x00, 0x00) }

            revert(0x00, 0x00)
        }
    }
}
