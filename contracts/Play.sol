// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./Random.sol";

uint constant half = 8;

contract Play{

    address payable public owner;

    constructor() payable{
        owner = payable(msg.sender);
    }

    mapping (address => uint) public balances;
    mapping (address => uint) public lastPlayed;

    event randomNumberLog(address player, uint randomNumber);
    event amountDeductedLog(address player, uint amount);
    event transferLog(address player, uint amount);

    function play() public payable returns (uint) {

        // Check if the player has played in the last 5 minutes
        require(block.timestamp - lastPlayed[msg.sender] > 5 minutes, "You have played recently, try again 5 minutes later");
        
        uint amountStaked = msg.value;

        // Check the the stake is required than 0.1 ether
        require(msg.value + balances[msg.sender] >= 0.1 ether, "You need to stake at least 0.1 ether");


        // Checks that player should not gamlbe more than 10 ether
        require(msg.value <= 10 ether, "You can't gamble more than 10 ether");

        // If balance of player becomes 100 ether, then he can't play anymore
        require(balances[msg.sender] <= 100 ether, "You can't have more than 100 ether, you need to withdraw some money");

        if (msg.value < 0.1 ether){
            require(balances[msg.sender] - (0.1 ether - msg.value) >= 0, "You don't have enough balance to play");
            // deduct the stake from the player's balance
            balances[msg.sender] -= 0.1 ether - msg.value;
            amountStaked = 0.1 ether;
            emit amountDeductedLog(msg.sender, 0.1 ether - msg.value);
        }

        // balance of player should be greater than amount staked, in case if player loses
        require(balances[msg.sender] - amountStaked >= 0, "You don't have enough balance to play");

        // Get a random number
        uint randomNumber = Random.normaliseRandom();
        emit randomNumberLog(msg.sender, randomNumber);

        // Check if the player won
        if (randomNumber < half){
            // Player won
            balances[msg.sender] += amountStaked + (amountStaked - amountStaked%2)/2;
        } else {
            // Player lost
            balances[msg.sender] -= amountStaked;
        }

        return randomNumber;
    }

    function withdraw(uint amount) public {
        // Check if the player has enough balance
        require(balances[msg.sender] >= amount, "You don't have enough balance to withdraw");

        // Transfer the amount to the player
        payable(msg.sender).transfer(amount);
        emit transferLog(msg.sender, amount);

        // Deduct the amount from the player's balance
        balances[msg.sender] -= amount;
    }

    function withdrawAll() public {
        // Check if the player has enough balance
        require(balances[msg.sender] > 0, "You don't have enough balance to withdraw");

        // Transfer the amount to the player
        payable(msg.sender).transfer(balances[msg.sender]);
        emit transferLog(msg.sender, balances[msg.sender]);

        // Deduct the amount from the player's balance
        balances[msg.sender] = 0;
    }

    function ownerWithdraw(uint amount) public {
        // Check if the player is the owner
        require(msg.sender == owner, "You are not the owner");

        // Transfer the amount to the owner
        owner.transfer(amount);
        emit transferLog(msg.sender, amount);
    }

    function ownerWithdrawAll() public {
        // Check if the player is the owner
        require(msg.sender == owner, "You are not the owner");

        // Transfer the amount to the owner
        owner.transfer(address(this).balance);
        emit transferLog(msg.sender, address(this).balance);
    }

    function ownerDeposit() public payable {
        // Check if the player is the owner
        require(msg.sender == owner, "You are not the owner");
    }

    function contractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getBalance() public view returns (uint) {
        return balances[msg.sender];
    }

    function getTestRandom() public payable returns (uint) {
        // requires fees of 0.001 ether
        require(msg.value == 0.001 ether, "You need to pay 0.001 ether to get a random number");
        emit randomNumberLog(msg.sender, Random.normaliseRandom());
        return Random.normaliseRandom();
    }
}

