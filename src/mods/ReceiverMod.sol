// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

/// @title Ether Deck Mk2 Reciver Mod
/// @author jtriley.eth
/// @notice a reasonably optimized token receiver mod for Ether Deck Mk2
/// @custom:lore as it turns out, erc-721 and erc-1155 require that if the
///         receiver of a transfer is a contract, it must implement the
///         onERC721Received or onERC1155Received functions, respectively. this
///         is both a waste of gas and an unnecessasry abstraction imposed on
///         the developers and users. the loophole here is the only thing the
///         token checks is that the selector of the callback is returned from
///         the receiver. this is cool bc in theory you could just.. blindly
///         return the selector if no mod is set, right? that'd be easy. BUT
///         erc-1271 deals in contract signatures, as in contracts can verify
///         signatures for transfer delegation flows, but would you believe it
///         the way contract confirms the signature is valid is to return the
///         selector of the isValidSignature callback. THEREFORE blindly
///         returning the selector is actually a critical vulnerability. so.
///         there is no simple solution to this problem that can be hard coded
///         without just discriminating against the belligerent token standards,
///         of which there will likely be more. so the workaround is this mod,
///         the ReceiverMod, which simply returns the selector blindly and can
///         be set to the dispatcher of the Ether Deck Mk2 for erc-721 and
///         erc-1155 callbacks. this means the token callbacks can point to this
///         mod and the erc-1271 callbacks can point to something that validates
///         the signature. this adds thousands of gas to simply receiving
///         erc-721 and erc-1155 tokens, but that cost is paid by the
///         transferrer, so silver lining for Ether Deck Mk2 runners.
contract ReceiverMod {
    mapping(bytes4 => address) internal dispatch;
    address internal runner;

    /// @notice returns the function selector
    /// @dev directives:
    ///      01. move selector from calldata to memory
    ///      02. return selector
    fallback() external payable {
        assembly {
            mstore(0x00, shl(0xe0, shr(0xe0, calldataload(0x00))))

            return(0x00, 0x20)
        }
    }

    receive() external payable { }
}
