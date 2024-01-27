// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

contract MockERC20 {
    event Transfer(address indexed sender, address indexed receiver, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    uint256 totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function transfer(address receiver, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[receiver] += amount;
        emit Transfer(msg.sender, receiver, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address receiver,
        uint256 amount
    ) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[receiver] += amount;
        emit Transfer(sender, receiver, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function mint(address receiver, uint256 amount) external {
        balanceOf[receiver] += amount;
        totalSupply += amount;
        emit Transfer(address(0), receiver, amount);
    }
}
