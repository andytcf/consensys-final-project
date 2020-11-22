pragma solidity ^0.6.0;

import "./Realty.sol";

contract ResidentialHome is Realty {

   constructor(
    string memory _streetName, 
    string memory _postCode,
    string memory _city,
    string memory _country
  ) public {
    streetName = _streetName;
    postCode = _postCode;
    city = _city;
    country = _country;
    realtyType = "Residential Home";
  }

}