// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

interface IFlashReceiver {
    function onFlashLoan(address, address, uint256, uint256, bytes calldata) external returns (bytes32);
}

contract DifferentialFlashMod {
    mapping(bytes4 => address) internal dispatch;
    address internal runner;

    uint256 internal constant divisor = 10_000;

    function setFlashFeeFactor(address token, uint256 factor) external {
        require(msg.sender == runner);

        require(factor <= divisor);

        bytes32 slot = keccak256(abi.encode(token, uint256(keccak256("EtherDeckMk2.FlashFeeSlotIndex")) - 1));

        assembly {
            sstore(slot, factor)
        }
    }

    function maxFlashLoan(address token) external view returns (uint256) {
        return getFlashFeeFactor(token) > 0 ? IERC20(token).balanceOf(address(this)) : 0;
    }

    function flashFee(address token, uint256 amount) external view returns (uint256) {
        require(getFlashFeeFactor(token) > 0);

        return getFlashFeeFactor(token) * amount / divisor;
    }

    function flashLoan(address receiver, address token, uint256 amount, bytes calldata data) external returns (bool) {
        require(getFlashFeeFactor(token) > 0);

        uint256 fee = getFlashFeeFactor(token) * amount / divisor;

        IERC20(token).transfer(receiver, amount);

        IFlashReceiver(receiver).onFlashLoan(msg.sender, token, amount, fee, data);

        IERC20(token).transferFrom(receiver, address(this), amount + fee);

        return true;
    }

    function getFlashFeeFactor(address token) internal view returns (uint256 factor) {
        bytes32 slot = keccak256(abi.encode(token, uint256(keccak256("EtherDeckMk2.FlashFeeSlotIndex")) - 1));

        assembly {
            factor := sload(slot)
        }
    }
}
