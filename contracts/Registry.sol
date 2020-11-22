pragma solidity ^0.6.2;

import "./Realty.sol";
import "./ResidentialHome.sol";

contract Registry {
  Realty[] realties;
  mapping(uint256 => address) public ownerOf;
  mapping (address => uint256[]) public realtyOwned;
  mapping(uint256 => Realty) public idToRealty;
  
  uint256 public registrations;

  uint public registryCreated;


  constructor() public {
    registryCreated = now;
    registrations = 0;
  }

  function registerHome(
    string memory _streetName,
    string memory _postCode,
    string memory _city,
    string memory _country
  ) public returns (ResidentialHome registeredHome) {
    registrations += 1;
    require(ownerOf[registrations] != address(0), "Realty already registered");

    registeredHome = new ResidentialHome(_streetName, _postCode, _city, _country);

    idToRealty[registrations] = registeredHome;
    realties.push(registeredHome);

    ownerOf[registrations] = msg.sender;
    
    uint256[] storage previousRealtyOwned = realtyOwned[msg.sender];

    previousRealtyOwned.push(registrations);
  }

  

}