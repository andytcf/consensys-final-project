pragma solidity ^0.6.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";


contract Registry is Ownable {
    using Address for address;

    event RegistrationAdded(uint256 registryId, address owner);
    event RegistrationRemoved(uint256 registryId);
    event RegistrationTransferred(uint256 registryId, address from, address to);

    mapping(uint256 => Realty) public idToRealty;
    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256[]) public realtyOwned;
    mapping(uint256 => uint256) public indexOfRealty;

    uint256 public totalRegistrations;
    uint public registryCreated;

    struct Realty {
        string streetName;
        string postCode;
        string city;
        string country;
        string realtyType;
        uint256 realtyId;
    }

    constructor() public {
        registryCreated = now;
    }

    function register(
        string memory streetName,
        string memory postCode,
        string memory city,
        string memory country,
        string memory realtyType,
        uint256 realtyId,
        address owner
    ) public onlyOwner returns (uint256) {
        require(ownerOf[realtyId] == address(0), "Realty already registered");

        Realty memory registeredRealty = Realty(streetName, postCode, city, country, realtyType, realtyId);
        idToRealty[realtyId] = registeredRealty;

        _register(realtyId, owner);

        return registeredRealty.realtyId;
    }

    function deregister(uint256 registryId) public onlyOwner {
        require(ownerOf[registryId] != address(0), "Realty is not registered");
        _deregister(registryId);
        emit RegistrationRemoved(registryId);
    }

    function transferOwner(
        address from,
        address to,
        uint256 registryId
    ) public onlyOwner {
        require(from != address(0), "Method called with the zero address");
        require(to != address(0), "Method called with the zero address");
        require(ownerOf[registryId] != address(0), "Realty is not registered");

        _deregister(registryId);

        _register(registryId, to);

        emit RegistrationTransferred(registryId, from, to);
    }

    function _register(uint256 realtyId, address owner) private {
        ownerOf[realtyId] = owner;

        uint256[] storage previousRealtyOwned = realtyOwned[owner];
        uint256 index = previousRealtyOwned.length;

        previousRealtyOwned.push(realtyId);

        indexOfRealty[realtyId] = index;

        emit RegistrationAdded(realtyId, owner);

        totalRegistrations++;
    }

    function _deregister(uint256 registryId) private {
        address previousOwner = ownerOf[registryId];
        uint256 index = indexOfRealty[registryId];

        uint256[] storage ownedAssets = realtyOwned[previousOwner];

        ownedAssets[index] = ownedAssets[ownedAssets.length - 1];

        ownedAssets.pop();

        delete ownerOf[registryId];
        delete idToRealty[registryId];
        delete indexOfRealty[registryId];

        totalRegistrations--;
    }
}
