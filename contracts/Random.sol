
// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.14;

uint constant prime = 17;

library Random {
    function random() private view returns (uint) {
        return uint(keccak256(abi.encode(blockhash(block.number-1), block.timestamp)));
    }
    function normaliseRandom() public view returns (uint) {
        return random() % prime;
    }
}