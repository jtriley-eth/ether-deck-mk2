// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

/// @title Ether Deck Mk2 Two Step Transfer Mod
/// @author jtriley.eth
/// @notice a reasonably optimized two step runner transfer mod for Ether Deck Mk2
contract TwoStepTransitionMod {
    mapping(bytes4 => address) internal dispatch;
    address internal runner;

    /// @notice starts a runner transition
    /// @dev directives:
    ///      01. if caller is not runner, revert
    ///      02. store newRunner in newRunner slot
    /// @dev newRunner slot is defined as `keccak256("EtherDeckMk2.NewRunner") - 1`
    function startRunnerTransition(address newRunner) external {
        assembly {
            if iszero(eq(caller(), sload(runner.slot))) { revert(0x00, 0x00) }

            sstore(0x91575d7bad3e5965f801b4ac5f4d48ffddfc86e1a6f2ba31dc5a35148e00e041, newRunner)
        }
    }

    /// @notice accepts a runner transition
    /// @dev directives:
    ///      01. load newRunner from newRunner slot
    ///      02. if caller is not newRunner, revert
    ///      03. store newRunner in runner slot
    function acceptRunnerTransition() external {
        assembly {
            let newRunner := sload(0x91575d7bad3e5965f801b4ac5f4d48ffddfc86e1a6f2ba31dc5a35148e00e041)

            if iszero(eq(newRunner, caller())) { revert(0x00, 0x00) }

            sstore(runner.slot, newRunner)
        }
    }
}
