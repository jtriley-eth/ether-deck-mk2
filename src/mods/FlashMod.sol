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
    /// @dev Directives:
    ///      01. if caller is not runner, revert
    ///      02. store token in memory
    ///      03. store flash fee slot index in memory
    ///      04. store the flash fee factor in storage at the slot hash
    /// @dev flash fee slot index is defined as `keccak256("EtherDeckMk2.FlashFeeSlotIndex") - 1`
    /// @param token the token to flash
    /// @param factor the flash fee factor in `1 / 10_000`
    function setFlashFeeFactor(address token, uint256 factor) external {
        assembly {
            if iszero(eq(sload(runner.slot), caller())) { revert(0x00, 0x00) }

            mstore(0x00, token)

            mstore(0x20, 0xf1eb8105a4a1127cc7c1f140012e33366c72dd5143314d8de5d93f0cd7b10318)

            sstore(keccak256(0x00, 0x40), factor)
        }
    }

    /// @notice gets max flash loan
    /// @dev Directives:
    ///      01. store `token.balanceOf.selector` in memory
    ///      02. store Ether Deck Mk2 address in memory
    ///      03. if call to `token.balanceOf` succeeds, return balance
    ///      04. else, return zero
    /// @param token the token to flash
    function maxFlashLoan(address token) external view returns (uint256) {
        assembly {
            mstore(0x00, 0x70a0823100000000000000000000000000000000000000000000000000000000)

            mstore(0x04, address())

            if staticcall(gas(), token, 0x00, 0x24, 0x00, 0x20) { return(0x00, 0x20) }

            return(0x80, 0x20)
        }
    }

    /// @notice gets flash fee for a given amount
    /// @dev Directives:
    ///      01. store token in memory
    ///      02. store flash fee slot index in memory
    ///      03. load the flash fee factor from storage, compute and store the flash fee in memory
    ///      04. return flash fee
    /// @dev flash fee slot index is defined as `keccak256("EtherDeckMk2.FlashFeeSlotIndex") - 1`
    /// @param token the token to flash
    /// @param amount the amount for which to compute the flash fee
    function flashFee(address token, uint256 amount) external view returns (uint256) {
        assembly {
            mstore(0x00, token)

            mstore(0x20, 0xf1eb8105a4a1127cc7c1f140012e33366c72dd5143314d8de5d93f0cd7b10318)

            mstore(0x00, div(mul(amount, sload(keccak256(0x00, 0x40))), divisor))

            return(0x00, 0x20)
        }
    }

    /// @notice flash loans
    /// @dev Directives:
    ///      01. store `token.transfer.selector` in memory
    ///      02. store transfer receiver in memory
    ///      03. store transfer amount in memory
    ///      04. call `token.transfer`; cache as success
    ///      05. check if returndata is either one or nothing; compose success
    ///      06. store `receiver.onFlashLoan` in memory
    ///      07. store onFlashLoan initiator in memory
    ///      08. store onFlashLoan token in memory
    ///      09. transiently store flash fee slot index in memory
    ///      10. load flash fee factor from storage and compute flash fee; cache as fee
    ///      11. store onFlashLoan amount in memory, overwriting flash fee slot index
    ///      12. store onFlashLoan fee in memory
    ///      13. store onFlashLoan data offset in memory
    ///      14. copy onFlashLoan data to memory
    ///      15. call `receiver.onFlashLoan`; compose success
    ///      16. check if returndata is onFlashLoan return value; compose success
    ///      17. store `token.transferFrom.selector` in memory
    ///      18. store transferFrom sender in memory (sender is flash receiver)
    ///      19. store transferFrom receiver in memory (receiver is the Ether Deck Mk2)
    ///      20. store trasnferFrom amount in memory (amount is sum of flash amount and fee)
    ///      21. call `token.transferFrom`; compose success
    ///      22. check if returndata is either one or nothing; compose success
    ///      23. store one (true) in memory
    ///      24. if success, return true
    ///      25. else, revert
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

            let fee := div(mul(amount, sload(keccak256(0x24, 0x40))), divisor)

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
