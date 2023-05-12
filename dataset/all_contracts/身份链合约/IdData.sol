pragma solidity ^0.4.4;

contract IdData {
    // String data
    string private data;
    
    // Getter function for string data
    function getData() public view returns (string memory) {
        return data;
    }
    
    // Setter function for string data
    function setData(string memory _data) public {
        data = _data;
    }
}