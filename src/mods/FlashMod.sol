// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

/// @title Ether Deck Mk2 Flash Mod
/// @author jtriley.eth
/// @notice a reasonably optimized erc-3156 compliant flash lender for Ether Deck Mk2
contract FlashMod {
    mapping(bytes4 => address) internal dispatch;
    address internal runner;
    uint256 internal nonce;

    /// @dev divisor of flash fee
    uint256 internal constant divisor = 10_000;

    /// @notice sets flash fee factor
    /// @dev directives:
    ///      01. if caller is not runner or factor is greater than divisor, revert
    ///      02. store token in memory
    ///      03. store flash fee slot index in memory
    ///      04. store the flash fee factor in storage at the slot hash
    /// @dev flash fee slot index is defined as `keccak256("EtherDeckMk2.FlashFeeSlotIndex") - 1`
    /// @param token the token to flash
    /// @param factor the flash fee factor in `1 / 10_000`
    function setFlashFeeFactor(address token, uint256 factor) external {
        assembly {
            if or(iszero(eq(caller(), sload(runner.slot))), gt(factor, divisor)) { revert(0x00, 0x00) }

            mstore(0x00, token)

            mstore(0x20, 0xf1eb8105a4a1127cc7c1f140012e33366c72dd5143314d8de5d93f0cd7b10318)

            sstore(keccak256(0x00, 0x40), factor)
        }
    }

    /// @notice gets max flash loan
    /// @dev directives:
    ///      01. store token in memory
    ///      02. store flash fee slot index in memory
    ///      03. compute flash fee factor slot, load from storage, check if nonzero; cache as success
    ///      04. store `token.balanceOf.selector` in memory
    ///      05. store Ether Deck Mk2 address in memory
    ///      06. staticcall to `token.balanceOf`; cache as success
    ///      07. if success, return balance
    ///      04. else, return zero
    /// @param token the token to flash
    function maxFlashLoan(address token) external view returns (uint256) {
        assembly {
            mstore(0x00, token)

            mstore(0x20, 0xf1eb8105a4a1127cc7c1f140012e33366c72dd5143314d8de5d93f0cd7b10318)

            let success := iszero(iszero(sload(keccak256(0x00, 0x40))))

            mstore(0x00, 0x70a0823100000000000000000000000000000000000000000000000000000000)

            mstore(0x04, address())

            success := and(success, staticcall(gas(), token, 0x00, 0x24, 0x00, 0x20))

            if success { return(0x00, 0x20) }

            return(0x80, 0x20)
        }
    }

    /// @notice gets flash fee for a given amount
    /// @dev directives:
    ///      01. store token in memory
    ///      02. store flash fee slot index in memory
    ///      03. load the flash fee factor from storage; cache as factor
    ///      04. begin fee computation; cache as fee
    ///      05. if fee is zero or fee multiplication step overflows, revert
    ///      06. finish fee computation, store in memory
    ///      07. return flash fee
    /// @dev flash fee slot index is defined as `keccak256("EtherDeckMk2.FlashFeeSlotIndex") - 1`
    /// @param token the token to flash
    /// @param amount the amount for which to compute the flash fee
    function flashFee(address token, uint256 amount) external view returns (uint256) {
        assembly {
            mstore(0x00, token)

            mstore(0x20, 0xf1eb8105a4a1127cc7c1f140012e33366c72dd5143314d8de5d93f0cd7b10318)

            let factor := sload(keccak256(0x00, 0x40))

            let fee := mul(amount, factor)

            let success := iszero(iszero(factor))

            success := and(success, or(eq(div(fee, amount), factor), iszero(amount)))

            mstore(0x00, div(fee, divisor))

            if success { return(0x00, 0x20) }

            revert(0x00, 0x00)
        }
    }

    /// @notice flash loans
    /// @dev directives:
    ///      01. store `token.transfer.selector` in memory
    ///      02. store transfer receiver in memory
    ///      03. store transfer amount in memory
    ///      04. call `token.transfer`; cache as success
    ///      05. check if returndata is either one or nothing; compose success
    ///      06. store `receiver.onFlashLoan` in memory
    ///      07. store onFlashLoan initiator in memory
    ///      08. store onFlashLoan token in memory
    ///      09. transiently store flash fee slot index in memory
    ///      10. compute flash fee factor slot and load from storage; cache as factor
    ///      11. check if factor is nonzero; compose success
    ///      12. begin fee computation; cache as fee
    ///      13. check if fee multiplication step overflows; compose success
    ///      14. finish fee computation; cache as fee
    ///      15. check if fee and amount overflow; compose success
    ///      16. store onFlashLoan amount in memory, overwriting flash fee slot index
    ///      17. store onFlashLoan fee in memory
    ///      18. store onFlashLoan data offset in memory
    ///      19. store onFlashLoan data length in memory
    ///      20. copy onFlashLoan data to memory
    ///      21. call `receiver.onFlashLoan`; compose success
    ///      22. check if returndata is onFlashLoan return value; compose success
    ///      23. store `token.transferFrom.selector` in memory
    ///      24. store transferFrom sender in memory (sender is flash receiver)
    ///      25. store transferFrom receiver in memory (receiver is the Ether Deck Mk2)
    ///      26. store trasnferFrom amount in memory (amount is sum of flash amount and fee)
    ///      27. call `token.transferFrom`; compose success
    ///      28. check if returndata is either one or nothing; compose success
    ///      29. store one (true) in memory
    ///      30. if success, return true
    ///      31. else, revert
    /// @dev flash fee slot index is defined as `keccak256("EtherDeckMk2.FlashFeeSlotIndex") - 1`
    /// @dev onFlashLoan return value is defined as `keccak256("ERC3156FlashBorrower.onFlashLoan")`
    /// @param receiver the receiver of the flash
    /// @param token the token to flash
    /// @param amount the amount to flash
    /// @param data the data to include in the flash callback
    /// @return success composed success of all items
    function flashLoan(address receiver, address token, uint256 amount, bytes calldata data) external returns (bool) {
        assembly {
            mstore(0x00, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)

            mstore(0x04, receiver)

            mstore(0x24, amount)

            let success := call(gas(), token, 0x00, 0x00, 0x44, 0x00, 0x20)

            success := and(success, or(iszero(returndatasize()), mload(0x00)))

            mstore(0x00, 0x23e30c8b00000000000000000000000000000000000000000000000000000000)

            mstore(0x04, caller())

            mstore(0x24, token)

            mstore(0x44, 0xf1eb8105a4a1127cc7c1f140012e33366c72dd5143314d8de5d93f0cd7b10318)

            let factor := sload(keccak256(0x24, 0x40))

            success := and(success, iszero(iszero(factor)))

            let fee := mul(amount, factor)

            success := and(success, or(eq(div(fee, amount), factor), iszero(amount)))

            fee := div(fee, divisor)

            success := and(success, iszero(lt(add(amount, fee), amount)))

            mstore(0x44, amount)

            mstore(0x64, fee)

            mstore(0x84, 0xa0)

            mstore(0xa4, data.length)

            calldatacopy(0xc4, data.offset, data.length)

            success := and(success, call(gas(), receiver, 0x00, 0x00, add(0xc4, data.length), 0x00, 0x20))

            success := and(success, eq(mload(0x00), 0x439148f0bbc682ca079e46d6e2c2f0c1e3b820f1a291b069d8882abf8cf18dd9))

            mstore(0x00, 0x23b872dd00000000000000000000000000000000000000000000000000000000)

            mstore(0x04, receiver)

            mstore(0x24, address())

            mstore(0x44, add(amount, fee))

            success := and(success, call(gas(), token, 0x00, 0x00, 0x64, 0x00, 0x20))

            success := and(success, or(iszero(returndatasize()), mload(0x00)))

            mstore(0x00, 0x01)

            if success { return(0x00, 0x20) }

            revert(0x00, 0x00)
        }
    }
}
