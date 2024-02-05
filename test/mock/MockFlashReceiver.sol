// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

import { MockERC20 } from "./MockERC20.sol";

contract MockFlashReceiver {
    event FlashLoan(address indexed initiator, address indexed token, uint256 amount, uint256 fee, bytes data);

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        MockERC20(token).approve(msg.sender, type(uint256).max);
        emit FlashLoan(initiator, token, amount, fee, data);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}
