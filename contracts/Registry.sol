pragma solidity ^0.6.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";


contract Registry is Ownable, Pausable {
    using Address for address;

    event RegistrationAdded(bytes32 registryId, address owner);
    event RegistrationRemoved(bytes32 registryId);

    event RealtyTransferred(bytes32 registryId, address from, address to);
    event RealtyPurchased(bytes32 registryId, uint price, address purchaser);
    event RealtyPriceUpdated(bytes32 registryId, uint price);
    event RealtyStateChanged(bytes32 registryId, RealtyState newState);

    mapping(bytes32 => Realty) public idToRealty;
    mapping(bytes32 => address) public ownerOf;
    mapping(address => bytes32[]) public realtyOwned;
    mapping(bytes32 => uint) public indexOfRealty;
    mapping(address => uint) public balance;

    uint public totalRegistrations;
    uint public registryCreated;

    enum RealtyState {Available, NotAvailable}

    struct Realty {
        string streetName;
        string postCode;
        string city;
        string country;
        string realtyType;
        bytes32 registryId;
        uint price;
        RealtyState state;
    }

    constructor() public {
        registryCreated = now;
    }

    modifier onlyRealtyOwner(bytes32 registryId) {
        require(ownerOf[registryId] == msg.sender, "Msg sender is not the owner of the Realty");
        _;
    }

    function register(
        string memory streetName,
        string memory postCode,
        string memory city,
        string memory country,
        string memory realtyType,
        uint price,
        address owner
    ) public whenNotPaused() onlyOwner() returns (bytes32) {
        bytes32 registryId = keccak256(abi.encodePacked(msg.sender, streetName, realtyType, now));

        require(ownerOf[registryId] == address(0), "Realty already registered");

        Realty memory registeredRealty = Realty(
            streetName,
            postCode,
            city,
            country,
            realtyType,
            registryId,
            price,
            RealtyState.NotAvailable
        );
        idToRealty[registryId] = registeredRealty;

        _register(registryId, owner);

        return registeredRealty.registryId;
    }

    function deregister(bytes32 registryId) public whenNotPaused() onlyOwner() {
        require(ownerOf[registryId] != address(0), "Realty is not registered");
        _deregister(registryId);
        emit RegistrationRemoved(registryId);
    }

    function purchaseRegistration(bytes32 registryId) public payable whenNotPaused() {
        Realty memory currentRealty = idToRealty[registryId];
        require(currentRealty.state == RealtyState.Available, "Realty is not for sale");
        require(msg.value >= currentRealty.price, "Insufficient value sent to purchase realty");

        address currentOwner = ownerOf[registryId];
        address purchaser = msg.sender;
        uint purchasedPrice = currentRealty.price;

        _transferOwner(currentOwner, purchaser, registryId);

        balance[currentOwner] = balance[currentOwner] + purchasedPrice;

        if (msg.value > currentRealty.price) {
            balance[purchaser] = balance[purchaser] + msg.value - currentRealty.price;
        }

        emit RealtyPurchased(registryId, purchasedPrice, purchaser);
    }

    function withdrawFunds() public {
        require(balance[msg.sender] > 0, "Insufficient funds to withdraw");
        uint amount = balance[msg.sender];
        balance[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

    function changePrice(bytes32 registryId, uint price) public whenNotPaused() onlyRealtyOwner(registryId) returns (uint) {
        require(price > 0, "Method called with an invalid price");
        idToRealty[registryId].price = price;
        emit RealtyPriceUpdated(registryId, price);
        return price;
    }

    function setAvailable(bytes32 registryId) public whenNotPaused() onlyRealtyOwner(registryId) {
        RealtyState currentState = idToRealty[registryId].state;
        require(currentState != RealtyState.Available, "Realty state already available");
        idToRealty[registryId].state = RealtyState.Available;
        emit RealtyStateChanged(registryId, RealtyState.Available);
    }

    function setNotAvailable(bytes32 registryId) public whenNotPaused() onlyRealtyOwner(registryId) {
        RealtyState currentState = idToRealty[registryId].state;
        require(currentState != RealtyState.NotAvailable, "Realty state already not available");
        idToRealty[registryId].state = RealtyState.NotAvailable;
        emit RealtyStateChanged(registryId, RealtyState.Available);
    }

    function _transferOwner(
        address from,
        address to,
        bytes32 registryId
    ) private {
        require(from != address(0), "Method called with the zero address");
        require(to != address(0), "Method called with the zero address");
        require(ownerOf[registryId] != address(0), "Realty is not registered");

        _deregister(registryId);
        _register(registryId, to);

        idToRealty[registryId].state = RealtyState.NotAvailable;

        emit RealtyTransferred(registryId, from, to);
    }

    function _register(bytes32 registryId, address owner) private {
        ownerOf[registryId] = owner;

        bytes32[] storage previousRealtyOwned = realtyOwned[owner];
        uint index = previousRealtyOwned.length;

        previousRealtyOwned.push(registryId);

        indexOfRealty[registryId] = index;

        emit RegistrationAdded(registryId, owner);

        totalRegistrations++;
    }

    function _deregister(bytes32 registryId) private {
        address previousOwner = ownerOf[registryId];
        uint index = indexOfRealty[registryId];

        bytes32[] storage ownedAssets = realtyOwned[previousOwner];

        ownedAssets[index] = ownedAssets[ownedAssets.length - 1];

        ownedAssets.pop();

        delete ownerOf[registryId];
        delete idToRealty[registryId];
        delete indexOfRealty[registryId];

        totalRegistrations--;
    }
}
