pragma solidity ^0.6.0;

contract Realty {

  string public streetName;
  string public postCode;
  string public city;
  string public country;
  string public realtyType;

  function getType() view external returns(string memory) {
    return realtyType;
  }

}