// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

contract MockERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    string public name;
    string public symbol;
    mapping(uint256 => string) public tokenURI;
    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    function mint(address to, uint256 id) public {
        ownerOf[id] = to;
        balanceOf[to]++;
        emit Transfer(address(0), to, id);
    }

    function approve(address spender, uint256 id) public {
        address owner = ownerOf[id];
        require(msg.sender == owner || isApprovedForAll[owner][msg.sender]);
        getApproved[id] = spender;
        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 id) public {
        require(from == ownerOf[id]);
        require(msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id]);
        balanceOf[from]--;
        balanceOf[to]++;
        ownerOf[id] = to;
        delete getApproved[id];
        emit Transfer(from, to, id);
    }
}
