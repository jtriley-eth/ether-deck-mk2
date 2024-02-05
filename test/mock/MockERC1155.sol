// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.24;

interface IERC1155TokenReceiver {
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external returns (bytes4);
}

contract MockERC1155 {
    event TransferSingle(
        address indexed operator, address indexed sender, address indexed receiver, uint256 id, uint256 amount
    );
    event TransferBatch(
        address indexed operator, address indexed sender, address indexed receiver, uint256[] ids, uint256[] amounts
    );
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    mapping(address => mapping(uint256 => uint256)) public balanceOf;
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    mapping(uint256 => string) public uri;

    function mint(address receiver, uint256 id, uint256 amount) public {
        balanceOf[receiver][id] += amount;
    }

    function setApprovalForAll(address operator, bool approved) public {
        emit ApprovalForAll(msg.sender, operator, isApprovedForAll[msg.sender][operator] = approved);
    }

    function safeTransferFrom(address sender, address receiver, uint256 id, uint256 amount, bytes calldata) public {
        require(msg.sender == sender || isApprovedForAll[sender][msg.sender]);
        balanceOf[sender][id] -= amount;
        balanceOf[receiver][id] += amount;
        emit TransferSingle(msg.sender, sender, receiver, id, amount);
    }
}
