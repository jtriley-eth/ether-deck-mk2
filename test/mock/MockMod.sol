// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

contract MockMod {
    event RunMod();

    function runMod() external {
        emit RunMod();
    }
}
