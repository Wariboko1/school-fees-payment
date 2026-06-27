// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Faucet is Ownable {
    // State variable
    IERC20 public token;
    uint256 public dripAmount;
    uint256 public cooldown = 1 days;

    mapping(address => uint256) public lastClaimTime;

    event TokenDispensed(address indexed recipient, uint256 amount);
    event FaucetFunded(address indexed funder, uint256 amount);
    event Withdrawn(address indexed owner, uint256 amount);

    constructor(address _token, uint256 _dripAmount) Ownable(msg.sender) {
        token = IERC20(_token);
        dripAmount = _dripAmount;
    }

    function requestToken() external {
        require(
            block.timestamp >= lastClaimTime[msg.sender] + cooldown,
            "Come back in 24 hours"
        );

        require(
            token.balanceOf(address(this)) >= dripAmount,
            "Faucet is empty"
        );
        lastClaimTime[msg.sender] = block.timestamp;
        token.transfer(msg.sender, dripAmount);

        emit TokenDispensed(msg.sender, dripAmount);
    }

    function faucetBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function timeUntilNextClaim(address _user) external view returns (uint256) {
        uint256 nextClaim = lastClaimTime[_user] + cooldown;
        if (block.timestamp >= nextClaim) return 0;
        return nextClaim - block.timestamp;
    }

    function setDripAmount(uint256 _newAmount) external onlyOwner {
        dripAmount = _newAmount;
    }

    function withdraw() external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "Nothing to withdraw");
        token.transfer(owner(), balance);
        emit Withdrawn(owner(), balance);
    }
}