// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

contract DifferentialTwoStepTransitionMod {
    mapping(bytes4 => address) internal dispatch;
    address internal runner;

    function startRunnerTransition(address newRunner) external {
        require(msg.sender == runner);
        uint256 slot = uint256(keccak256("EtherDeckMk2.NewRunner")) - 1;
        assembly {
            sstore(slot, newRunner)
        }
    }

    function acceptRunnerTransition() external {
        uint256 slot = uint256(keccak256("EtherDeckMk2.NewRunner")) - 1;
        address newRunner;
        assembly {
            newRunner := sload(slot)
        }
        require(msg.sender == newRunner);
        runner = newRunner;
    }
}
