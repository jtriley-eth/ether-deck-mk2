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
    /// @dev newRunner slot is defined as `keccak256("EtherDeckMk2.TwoStepTransitionMod.newRunner") - 1`
    function startRunnerTransition(address newRunner) external {
        assembly {
            if iszero(eq(caller(), sload(runner.slot))) { revert(0x00, 0x00) }

            sstore(0x1135fd56f406be55915358ca5fba26244b149720a5a3d009d6554ab509882baa, newRunner)
        }
    }

    /// @notice accepts a runner transition
    /// @dev directives:
    ///      01. load newRunner from newRunner slot
    ///      02. if caller is not newRunner, revert
    ///      03. store newRunner in runner slot
    function acceptRunnerTransition() external {
        assembly {
            let newRunner := sload(0x1135fd56f406be55915358ca5fba26244b149720a5a3d009d6554ab509882baa)

            if iszero(eq(newRunner, caller())) { revert(0x00, 0x00) }

            sstore(runner.slot, newRunner)
        }
    }
}
