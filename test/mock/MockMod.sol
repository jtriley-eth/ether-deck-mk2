// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

contract MockMod {
    mapping(bytes4 => address) internal dispatch;
    address internal runner;
    uint256 internal __padding;
    bool internal throws;

    event RunMod();
    event Fallback();

    function setThrows(bool _throws) external {
        throws = _throws;
    }

    function runMod() external {
        require(!throws);
        emit RunMod();
    }

    fallback() external {
        require(!throws);
        emit Fallback();
    }
}
