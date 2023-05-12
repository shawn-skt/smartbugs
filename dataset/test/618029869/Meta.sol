pragma solidity ^0.4.25;
contract Meta {
    function lastBlockHash() public view returns (bytes32) {
        return blockhash(block.number - 1);
    }
}

