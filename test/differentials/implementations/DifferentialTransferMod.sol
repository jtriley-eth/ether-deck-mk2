// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

import { MockERC20 } from "../../mock/MockERC20.sol";
import { MockERC721 } from "../../mock/MockERC721.sol";
import { MockERC1155 } from "../../mock/MockERC1155.sol";
import { MockERC6909 } from "../../mock/MockERC6909.sol";

contract DifferentialTransferMod {
    mapping(bytes4 => address) internal dispatch;
    address internal runner;

    function transferEther(address[] calldata receivers, uint256[] calldata amounts) external payable {
        require(msg.sender == runner);
        require(receivers.length == amounts.length);

        for (uint256 i; i < receivers.length; i++) {
            (bool succ, ) = receivers[i].call{ value: amounts[i] }(new bytes(0));
            require(succ);
        }
    }

    function transferERC20(
        address[] calldata tokens,
        address[] calldata receivers,
        uint256[] calldata amounts
    ) external {
        require(msg.sender == runner);
        require(tokens.length == receivers.length);
        require(tokens.length == amounts.length);

        for (uint256 i; i < tokens.length; i++) {
            MockERC20(tokens[i]).transfer(receivers[i], amounts[i]);
        }
    }

    function transferERC721(address[] calldata tokens, address[] calldata receivers, uint256[] calldata ids) external {
        require(msg.sender == runner);
        require(tokens.length == receivers.length);
        require(tokens.length == ids.length);

        for (uint256 i; i < tokens.length; i++) {
            MockERC721(tokens[i]).transferFrom(address(this), receivers[i], ids[i]);
        }
    }

    function transferERC1155(
        address[] calldata tokens,
        address[] calldata receivers,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external {
        require(msg.sender == runner);
        require(tokens.length == receivers.length);
        require(tokens.length == ids.length);
        require(tokens.length == amounts.length);

        for (uint256 i; i < tokens.length; i++) {
            MockERC1155(tokens[i]).safeTransferFrom(address(this), receivers[i], ids[i], amounts[i], "");
        }
    }

    function transferERC6909(
        address[] calldata tokens,
        address[] calldata receivers,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external {
        require(msg.sender == runner);
        require(tokens.length == receivers.length);
        require(tokens.length == ids.length);
        require(tokens.length == amounts.length);

        for (uint256 i; i < tokens.length; i++) {
            MockERC6909(tokens[i]).transferFrom(address(this), receivers[i], ids[i], amounts[i]);
        }
    }
}
