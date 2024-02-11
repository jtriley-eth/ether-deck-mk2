// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

/// @title Ether Deck Mk2 Mass Revoke Mod
/// @author jtriley.eth
/// @notice a reasonably optimized approval revocation mod for Ether Deck Mk2
/// @dev supports erc-20, erc-721, erc-1155, and erc-6909
contract RevokeMod {
    mapping(bytes4 => address) internal dispatch;
    address internal runner;

    /// @notice revokes approvals for erc-20 tokens
    /// @dev directives:
    ///      01. check if caller is runner; cache as success
    ///      02. load token offset; cache as tokenOffset
    ///      03. load spender offset; cache as spenderOffset
    ///      04. compute end of tokens; cache as tokensEnd
    ///      05. check if tokens and spenders are equal length; compose success
    ///      06. store `erc20.approve.selector` in memory
    ///      07. store approve boolean in memory
    ///      08. loop:
    ///          a. if tokenOffset is tokensEnd, break loop
    ///          b. move spender from calldata to memory
    ///          c. call `erc20.approve`; compose success
    ///          d. check that the return value is either true or nothing; compose success
    ///          e. increment tokenOffset
    ///          f. increment spenderOffset
    ///      09. if success, return
    ///      10. else, revert
    /// @param tokens the tokens to revoke approval for
    /// @param spenders the spenders to revoke approval for
    function revokeERC20Approval(address[] calldata tokens, address[] calldata spenders) external {
        assembly {
            let success := eq(caller(), sload(runner.slot))

            let tokenOffset := tokens.offset

            let spenderOffset := spenders.offset

            let tokensEnd := add(tokenOffset, mul(tokens.length, 0x20))

            success := and(success, eq(tokens.length, spenders.length))

            mstore(0x00, 0x095ea7b300000000000000000000000000000000000000000000000000000000)

            mstore(0x24, 0x00)

            for { } 1 { } {
                if eq(tokenOffset, tokensEnd) { break }

                mstore(0x04, calldataload(spenderOffset))

                success := and(success, call(gas(), calldataload(tokenOffset), 0x00, 0x00, 0x44, 0x44, 0x20))

                success := and(success, or(iszero(returndatasize()), mload(0x44)))

                tokenOffset := add(tokenOffset, 0x20)

                spenderOffset := add(spenderOffset, 0x20)
            }

            if success { return(0x00, 0x00) }

            revert(0x00, 0x00)
        }
    }

    /// @notice revokes approvals for erc-721 tokens
    /// @dev directives:
    ///      01. check if caller is runner; cache as success
    ///      02. load token offset; cache as tokenOffset
    ///      03. load id offset; cache as idOffset
    ///      04. compute end of tokens; cache as tokensEnd
    ///      05. check if tokens and ids are equal length; compose success
    ///      06. store `erc721.approve.selector` in memory
    ///      07. loop:
    ///          a. if tokenOffset is tokensEnd, break loop
    ///          b. move id from calldata to memory
    ///          c. call `erc721.approve`; compose success
    ///          d. increment tokenOffset
    ///          e. increment idOffset
    ///      08. if success, return
    ///      09. else, revert
    /// @dev erc721.approve `_approved` argument is implicitly zero at memory[0x04]
    /// @param tokens the tokens to revoke approval for
    /// @param ids the ids to revoke approval for
    function revokeERC721Approval(address[] calldata tokens, uint256[] calldata ids) external {
        assembly {
            let success := eq(caller(), sload(runner.slot))

            let tokenOffset := tokens.offset

            let idOffset := ids.offset

            let tokensEnd := add(tokenOffset, mul(tokens.length, 0x20))

            success := and(success, eq(tokens.length, ids.length))

            mstore(0x00, 0x095ea7b300000000000000000000000000000000000000000000000000000000)

            for { } 1 { } {
                if eq(tokenOffset, tokensEnd) { break }

                mstore(0x24, calldataload(idOffset))

                success := and(success, call(gas(), calldataload(tokenOffset), 0x00, 0x00, 0x44, 0x00, 0x00))

                tokenOffset := add(tokenOffset, 0x20)

                idOffset := add(idOffset, 0x20)
            }

            if success { return(0x00, 0x00) }

            revert(0x00, 0x00)
        }
    }

    /// @notice revokes approvals for erc-6909 tokens
    /// @dev directives:
    ///      01. check if caller is runner; cache as success
    ///      02. load token offset; cache as tokenOffset
    ///      03. load id offset; cache as idOffset
    ///      04. load operator offset; cache as operatorOffset
    ///      05. compute end of tokens; cache as tokensEnd
    ///      06. check if tokens and ids are equal length; compose success
    ///      07. check if tokens and operators are equal length; compose success
    ///      08. store `erc6909.approve.selector` in memory
    ///      09. store approve boolean in memory
    ///      10. loop:
    ///          a. if tokenOffset is tokensEnd, break loop
    ///          b. move id from calldata to memory
    ///          c. move operator from calldata to memory
    ///          d. call `erc6909.approve`; compose success
    ///          e. check that the return value is true; compose success
    ///          f. increment tokenOffset
    ///          g. increment idOffset
    ///          h. increment operatorOffset
    ///      11. if success, return
    ///      12. else, revert
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

            let tokenOffset := tokens.offset

            let idOffset := ids.offset

            let operatorOffset := operators.offset

            let tokensEnd := add(tokenOffset, mul(tokens.length, 0x20))

            success := and(success, eq(tokens.length, ids.length))

            success := and(success, eq(tokens.length, operators.length))

            mstore(0x00, 0x426a849300000000000000000000000000000000000000000000000000000000)

            mstore(0x44, 0x00)

            for { } 1 { } {
                if eq(tokenOffset, tokensEnd) { break }

                mstore(0x04, calldataload(operatorOffset))

                mstore(0x24, calldataload(idOffset))

                success := and(success, call(gas(), calldataload(tokenOffset), 0x00, 0x00, 0x64, 0x64, 0x20))

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
    /// @dev directives:
    ///      01. check if caller is runner; cache as success
    ///      02. load token offset; cache as tokenOffset
    ///      03. load operator offset; cache as operatorOffset
    ///      04. compute end of tokens; cache as tokensEnd
    ///      05. check if tokens and operators are equal length; compose success
    ///      06. store `{erc721, erc1155}.setApprovalForAll.selector` in memory
    ///      07. store approve boolean in memory
    ///      08. loop:
    ///          a. if tokenOffset is tokensEnd, break loop
    ///          b. move operator from calldata to memory
    ///          c. call `{erc721, erc1155}.setApprovalForAll`; compose success
    ///          d. increment tokenOffset
    ///          e. increment operatorOffset
    ///      09. if success, return
    ///      10. else, revert
    /// @param tokens the tokens to revoke approval for
    /// @param operators the operators to revoke approval for
    function revokeApprovalForAll(address[] calldata tokens, address[] calldata operators) external {
        assembly {
            let success := eq(caller(), sload(runner.slot))

            let tokenOffset := tokens.offset

            let operatorOffset := operators.offset

            let tokensEnd := add(tokenOffset, mul(tokens.length, 0x20))

            success := and(success, eq(tokens.length, operators.length))

            mstore(0x00, 0xa22cb46500000000000000000000000000000000000000000000000000000000)

            mstore(0x44, 0x00)

            for { } 1 { } {
                if eq(tokenOffset, tokensEnd) { break }

                mstore(0x04, calldataload(operatorOffset))

                success := and(success, call(gas(), calldataload(tokenOffset), 0x00, 0x00, 0x64, 0x00, 0x00))

                tokenOffset := add(tokenOffset, 0x20)

                operatorOffset := add(operatorOffset, 0x20)
            }

            if success { return(0x00, 0x00) }

            revert(0x00, 0x00)
        }
    }

    /// @notice revokes operator approvals for erc-6909 tokens
    /// @dev directives:
    ///      01. check if caller is runner; cache as success
    ///      02. load token offset; cache as tokenOffset
    ///      03. load operator offset; cache as operatorOffset
    ///      04. compute end of tokens; cache as tokensEnd
    ///      05. check if tokens and operators are equal length; compose success
    ///      06. store `erc6909.setOperator.selector` in memory
    ///      07. loop:
    ///          a. if tokenOffset is tokensEnd, break loop
    ///          b. move operator from calldata to memory
    ///          c. call `erc6909.setOperator`; compose success
    ///          d. check that the return value is true; compose success
    ///          e. increment tokenOffset
    ///          f. increment operatorOffset
    ///      08. if success, return
    ///      09. else, revert
    function revokeOperator(address[] calldata tokens, address[] calldata operators) external {
        assembly {
            let success := eq(caller(), sload(runner.slot))

            let tokenOffset := tokens.offset

            let operatorOffset := operators.offset

            let tokensEnd := add(tokenOffset, mul(tokens.length, 0x20))

            success := and(success, eq(tokens.length, operators.length))

            mstore(0x00, 0x558a729700000000000000000000000000000000000000000000000000000000)

            mstore(0x24, 0x00)

            for { } 1 { } {
                if eq(tokenOffset, tokensEnd) { break }

                mstore(0x04, calldataload(operatorOffset))

                success := and(success, call(gas(), calldataload(tokenOffset), 0x00, 0x00, 0x44, 0x44, 0x20))

                success := and(success, mload(0x44))

                tokenOffset := add(tokenOffset, 0x20)

                operatorOffset := add(operatorOffset, 0x20)
            }

            if success { return(0x00, 0x00) }

            revert(0x00, 0x00)
        }
    }
}
