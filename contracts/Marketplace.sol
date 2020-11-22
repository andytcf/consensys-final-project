pragma solidity ^0.6.2;

contract Marketplace {

  struct Storefront {
    string name;
    address owner;
    uint256 itemCount;
  }

  struct Listing {
    address owner;
    bool isAuction;
    uint256 price;
  }

  constructor() public {

  }
}