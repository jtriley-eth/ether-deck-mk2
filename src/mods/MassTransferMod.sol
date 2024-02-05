// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

/// @title Ether Deck Mk2 Mass Transfer Modu
/// @author jtriley.eth
/// @notice a reasonably optimized transfer mod for Ether Deck Mk2
/// @dev supports erc-20, erc-721, erc-1155, and erc-6909
contract MassTransferMod {
    mapping(bytes4 => address) internal dispatch;
    address internal runner;

    /// @notice transfers erc-20 tokens
    /// @dev directives:
    ///      01. check if caller is runner; cache as success
    ///      02. load token offset; cache as tokenOffset
    ///      03. load receiver offset; cache as receiverOffset
    ///      04. load amount offset; cache as amountOffset
    ///      05. compute end of tokens; cache as tokensEnd
    ///      06. check if tokens and receivers are equal length; compose success
    ///      07. check if tokens and amounts are equal length; compose success
    ///      08. store `erc20.transfer` selector in memory
    ///      09. loop:
    ///          a. if tokenOffset is tokensEnd, break loop
    ///          b. move receiver from calldata to memory
    ///          c. move amount from calldata to memory
    ///          d. call `erc20.transfer`; compose success
    ///          e. check that the return value is either true or nothing; compose success
    ///          f. increment tokenOffset
    ///          g. increment receiverOffset
    ///          h. increment amountOffset
    ///      10. if success, return
    ///      11. else, revert
    /// @param tokens the tokens to transfer
    /// @param receivers the receivers of the tokens
    /// @param amounts the amounts of tokens to transfer
    function transferERC20(
        address[] calldata tokens,
        address[] calldata receivers,
        uint256[] calldata amounts
    ) external {
        assembly {
            let success := eq(caller(), sload(runner.slot))

            let tokenOffset := tokens.offset

            let receiverOffset := receivers.offset

            let amountOffset := amounts.offset

            let tokensEnd := add(tokenOffset, mul(tokens.length, 0x20))

            success := and(success, eq(tokens.length, receivers.length))

            success := and(success, eq(tokens.length, amounts.length))

            mstore(0x00, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)

            for { } 1 { } {
                if eq(tokenOffset, tokensEnd) { break }

                mstore(0x04, calldataload(receiverOffset))

                mstore(0x24, calldataload(amountOffset))

                success := and(success, call(gas(), calldataload(tokenOffset), 0x00, 0x00, 0x44, 0x44, 0x20))

                success := and(success, or(iszero(returndatasize()), mload(0x44)))

                tokenOffset := add(tokenOffset, 0x20)

                receiverOffset := add(receiverOffset, 0x20)

                amountOffset := add(amountOffset, 0x20)
            }

            if success { return(0x00, 0x00) }

            revert(0x00, 0x00)
        }
    }

    /// @notice transfers erc-721 tokens
    /// @dev directives:
    ///      01. check if caller is runner; cache as success
    ///      02. load token offset; cache as tokenOffset
    ///      03. load receiver offset; cache as receiverOffset
    ///      04. load id offset; cache as idOffset
    ///      05. compute end of tokens; cache as tokensEnd
    ///      06. check if tokens and receivers are equal length; compose success
    ///      07. check if tokens and ids are equal length; compose success
    ///      08. store `erc721.transferFrom` selector in memory
    ///      09. store self address in memory
    ///      10. loop:
    ///          a. if tokenOffset is tokensEnd, break loop
    ///          b. move receiver from calldata to memory
    ///          c. move id from calldata to memory
    ///          d. call `erc721.transferFrom`; compose success
    ///          e. increment tokenOffset
    ///          f. increment receiverOffset
    ///          g. increment idOffset
    ///      11. if success, return
    ///      12. else, revert
    /// @param tokens the tokens to transfer
    /// @param receivers the receivers of the tokens
    /// @param ids the ids of the tokens to transfer
    function transferERC721(address[] calldata tokens, address[] calldata receivers, uint256[] calldata ids) external {
        assembly {
            let success := eq(caller(), sload(runner.slot))

            let tokenOffset := tokens.offset

            let receiverOffset := receivers.offset

            let idsOffset := ids.offset

            let tokensOffset := add(tokenOffset, mul(tokens.length, 0x20))

            success := and(success, eq(tokens.length, receivers.length))

            success := and(success, eq(tokens.length, ids.length))

            mstore(0x00, 0x23b872dd00000000000000000000000000000000000000000000000000000000)

            mstore(0x04, address())

            for { } 1 { } {
                if eq(tokenOffset, tokensOffset) { break }

                mstore(0x24, calldataload(receiverOffset))

                mstore(0x44, calldataload(idsOffset))

                success := and(success, call(gas(), calldataload(tokenOffset), 0x00, 0x00, 0x64, 0x00, 0x00))

                tokenOffset := add(tokenOffset, 0x20)

                receiverOffset := add(receiverOffset, 0x20)

                idsOffset := add(idsOffset, 0x20)
            }

            if success { return(0x00, 0x00) }

            revert(0x00, 0x00)
        }
    }

    /// @notice transfers erc-1155 tokens
    /// @dev directives:
    ///      01. check if caller is runner; cache as success
    ///      02. load token offset; cache as tokenOffset
    ///      03. load receiver offset; cache as receiverOffset
    ///      04. load id offset; cache as idOffset
    ///      05. load amount offset; cache as amountOffset
    ///      06. compute end of tokens; cache as tokensEnd
    ///      07. check if tokens and receivers are equal length; compose success
    ///      08. check if tokens and ids are equal length; compose success
    ///      09. check if tokens and amounts are equal length; compose success
    ///      10. store `erc1155.safeTransferFrom` selector in memory
    ///      11. store self address in memory
    ///      12. store empty bytes data in memory
    ///      13. loop:
    ///          a. if tokenOffset is tokensEnd, break loop
    ///          b. move receiver from calldata to memory
    ///          c. move id from calldata to memory
    ///          d. move amount from calldata to memory
    ///          e. call `erc1155.safeTransferFrom`; compose success
    ///          f. increment tokenOffset
    ///          g. increment receiverOffset
    ///          h. increment idOffset
    ///          i. increment amountOffset
    ///      14. if success, return
    ///      15. else, revert
    /// @param tokens the tokens to transfer
    /// @param receivers the receivers of the tokens
    /// @param ids the ids of the tokens to transfer
    /// @param amounts the amounts of tokens to transfer
    function transferERC1155(
        address[] calldata tokens,
        address[] calldata receivers,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external {
        assembly {
            let success := eq(caller(), sload(runner.slot))

            let tokenOffset := tokens.offset

            let receiverOffset := receivers.offset

            let idsOffset := ids.offset

            let amountOffset := amounts.offset

            let tokensEnd := add(tokenOffset, mul(tokens.length, 0x20))

            success := and(success, eq(tokens.length, receivers.length))

            success := and(success, eq(tokens.length, ids.length))

            success := and(success, eq(tokens.length, amounts.length))

            mstore(0x00, 0xf242432a00000000000000000000000000000000000000000000000000000000)

            mstore(0x04, address())

            mstore(0x84, 0xa0)

            for { } 1 { } {
                if eq(tokenOffset, tokensEnd) { break }

                mstore(0x24, calldataload(receiverOffset))

                mstore(0x44, calldataload(idsOffset))

                mstore(0x64, calldataload(amountOffset))

                success := and(success, call(gas(), calldataload(tokenOffset), 0x00, 0x00, 0xc4, 0x00, 0x00))

                tokenOffset := add(tokenOffset, 0x20)

                receiverOffset := add(receiverOffset, 0x20)

                idsOffset := add(idsOffset, 0x20)

                amountOffset := add(amountOffset, 0x20)
            }

            if success { return(0x00, 0x00) }

            revert(0x00, 0x00)
        }
    }

    /// @notice transfers erc-6909 tokens
    /// @dev directives:
    ///      01. check if caller is runner; cache as success
    ///      02. load token offset; cache as tokenOffset
    ///      03. load receiver offset; cache as receiverOffset
    ///      04. load id offset; cache as idOffset
    ///      05. load amount offset; cache as 
    ///      06. compute end of tokens; cache as tokensEnd
    ///      07. check if tokens and receivers are equal length; compose success
    ///      08. check if tokens and ids are equal length; compose success
    ///      09. check if tokens and amounts are equal length; compose success
    ///      10. store `erc6909.transfer` selector in memory
    ///      11. loop:
    ///          a. if tokenOffset is tokensEnd, break loop
    ///          b. move receiver from calldata to memory
    ///          c. move id from calldata to memory
    ///          d. move amount from calldata to memory
    ///          e. call `erc6909.transfer`; compose success
    ///          f. check that the return value is either true or nothing; compose success
    ///          g. increment tokenOffset
    ///          h. increment receiverOffset
    ///          i. increment idOffset
    ///          j. increment amountOffset
    ///      12. if success, return
    ///      13. else, revert
    function transferERC6909(
        address[] calldata tokens,
        address[] calldata receivers,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external {
        assembly {
            let success := eq(caller(), sload(runner.slot))

            let tokenOffset := tokens.offset

            let receiverOffset := receivers.offset

            let idsOffset := ids.offset

            let amountOffset := amounts.offset

            let tokensEnd := add(tokenOffset, mul(tokens.length, 0x20))

            success := and(success, eq(tokens.length, receivers.length))

            success := and(success, eq(tokens.length, ids.length))

            success := and(success, eq(tokens.length, amounts.length))

            mstore(0x00, 0x095bcdb600000000000000000000000000000000000000000000000000000000)

            for { } 1 { } {
                if eq(tokenOffset, tokensEnd) { break }

                mstore(0x04, calldataload(receiverOffset))

                mstore(0x24, calldataload(idsOffset))

                mstore(0x44, calldataload(amountOffset))

                success := and(success, call(gas(), calldataload(tokenOffset), 0x00, 0x00, 0x64, 0x64, 0x20))

                success := and(success, mload(0x64))

                tokenOffset := add(tokenOffset, 0x20)

                receiverOffset := add(receiverOffset, 0x20)

                idsOffset := add(idsOffset, 0x20)

                amountOffset := add(amountOffset, 0x20)
            }

            if success { return(0x00, 0x00) }

            revert(0x00, 0x00)
        }
    }
}
