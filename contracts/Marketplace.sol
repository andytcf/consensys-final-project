pragma solidity ^0.6.2;


contract Marketplace {
    event NewListing(uint listingId, address owner);
    event RemovedListing(uint listingId, address owner);

    struct Storefront {
        string name;
        address owner;
        uint itemCount;
        string image;
    }

    struct Listing {
        address owner;
        bool isAuction;
        uint price;
        uint listingTimestamp;
    }

    mapping(uint => Listing) public listings;
    mapping(uint => Storefront) public storefronts;

    constructor() public {}

    function postListing() public returns (uint) {}

    function removeListing() public returns (bool) {}

    function purchaseListing() public returns (uint) {}
}
