// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

import { MockERC20 } from "../../mock/MockERC20.sol";
import { MockERC721 } from "../../mock/MockERC721.sol";
import { MockERC1155 } from "../../mock/MockERC1155.sol";
import { MockERC6909 } from "../../mock/MockERC6909.sol";

contract DifferentialMassRevokeMod {
    mapping(bytes4 => address) internal dispatch;
    address internal runner;

    function revokeERC20Approval(address[] calldata tokens, address[] calldata spenders) external {
        require(msg.sender == runner);
        require(tokens.length == spenders.length);

        for (uint256 i; i < tokens.length; i++) {
            MockERC20(tokens[i]).approve(spenders[i], 0);
        }
    }

    function revokeERC721Approval(address[] calldata tokens, uint256[] calldata ids) external {
        require(msg.sender == runner);
        require(tokens.length == ids.length);

        for (uint256 i; i < tokens.length; i++) {
            MockERC721(tokens[i]).approve(address(0), ids[i]);
        }
    }

    function revokeERC6909Approval(
        address[] calldata tokens,
        uint256[] calldata ids,
        address[] calldata operators
    ) external {
        require(msg.sender == runner);
        require(tokens.length == ids.length);
        require(tokens.length == operators.length);

        for (uint256 i; i < tokens.length; i++) {
            MockERC6909(tokens[i]).approve(operators[i], ids[i], 0);
        }
    }

    function revokeApprovalForAll(address[] calldata tokens, address[] calldata operators) external {
        require(msg.sender == runner);
        require(tokens.length == operators.length);

        for (uint256 i; i < tokens.length; i++) {
            MockERC1155(tokens[i]).setApprovalForAll(operators[i], false);
        }
    }

    function revokeOperator(address[] calldata tokens, address[] calldata operators) external {
        require(msg.sender == runner);
        require(tokens.length == operators.length);

        for (uint256 i; i < tokens.length; i++) {
            MockERC6909(tokens[i]).setOperator(operators[i], false);
        }
    }
}
