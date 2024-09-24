pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
import "./YourToken.sol";

contract Vendor is Ownable {
	event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
	event SellTokens(
		address seller,
		uint256 amountOfTokens,
		uint256 amountOfETH
	);

	uint256 public constant tokensPerEth = 100;
	YourToken public yourToken;
	uint256 public currentBalance;

	mapping(address => uint256) public balances;

	constructor(address tokenAddress) {
		yourToken = YourToken(tokenAddress);
		currentBalance = yourToken.balanceOf(address(this));
	}

	// ToDo: create a payable buyTokens() function:
	function buyTokens() public payable {
		require(msg.value > 0, "Send ETH to buy tokens");
		uint256 amountOfTokens = msg.value * tokensPerEth;
		console.log("debug", msg.value, amountOfTokens);
		balances[msg.sender] += amountOfTokens;
		yourToken.transfer(msg.sender, amountOfTokens);

		emit BuyTokens(msg.sender, msg.value, amountOfTokens);
	}

	// ToDo: create a withdraw() function that lets the owner withdraw ETH
	function withdraw() public {
		// this pattern solves the re-entrancy hack
		uint256 amount = balances[msg.sender];
		balances[msg.sender] = 0;
		(bool status, ) = msg.sender.call{ value: amount }("");
		require(status, "Failed to withdraw funds");
	}

	function sellTokens(uint256 _amount) public {
		require(_amount > 0, "Must sell at least 1 token");
		require(
			yourToken.balanceOf(msg.sender) >= _amount,
			"Insufficient token balance"
		);

		// Calculate the _amount of ETH to send back
		uint256 ethAmount = _amount / tokensPerEth;

		// Ensure the vendor has enough ETH to pay
		require(
			address(this).balance >= ethAmount,
			"Not enough ETH in the vendor"
		);

		// Transfer tokens from the seller to the Vendor
		yourToken.transferFrom(msg.sender, address(this), _amount);

		// Transfer ETH to the seller using call
		(bool success, ) = msg.sender.call{ value: ethAmount }("");
		require(success, "Failed to send ETH");

		// Emit an event for the sale
		emit SellTokens(msg.sender, _amount, ethAmount);
	}
}
