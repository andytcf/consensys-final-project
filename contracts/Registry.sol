pragma solidity ^0.6.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";


contract Registry is Ownable, Pausable {
    using Address for address;

    event RegistrationAdded(uint registryId, address owner);
    event RegistrationRemoved(uint registryId);

    event RealtyTransferred(uint registryId, address from, address to);
    event RealtyPurchased(uint registryId, uint price, address purchaser);
    event RealtyPriceUpdated(uint registryId, uint price);
    event RealtyStateChanged(uint registryId, RealtyState newState);

    mapping(uint => Realty) public idToRealty;
    mapping(uint => address) public ownerOf;
    mapping(address => uint[]) public realtyOwned;
    mapping(uint => uint) public indexOfRealty;
    mapping(address => uint) public balance;

    uint public totalRegistrations;
    uint public currentID;
    uint public registryCreated;

    enum RealtyState {Available, NotAvailable}

    struct Realty {
        string streetName;
        string postCode;
        string city;
        string country;
        string realtyType;
        uint registryId;
        uint price;
        RealtyState state;
    }

    constructor() public {
        registryCreated = now;
    }

    modifier onlyRealtyOwner(uint registryId) {
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
    ) public whenNotPaused() onlyOwner() returns (uint) {
        Realty memory registeredRealty = Realty(
            streetName,
            postCode,
            city,
            country,
            realtyType,
            currentID,
            price,
            RealtyState.NotAvailable
        );

        idToRealty[currentID] = registeredRealty;

        _register(currentID, owner);

        currentID++;

        return registeredRealty.registryId;
    }

    function deregister(uint registryId) public whenNotPaused() onlyOwner() {
        require(ownerOf[registryId] != address(0), "Realty is not registered");
        _deregister(registryId);
        emit RegistrationRemoved(registryId);
    }

    function purchaseRegistration(uint registryId) public payable whenNotPaused() {
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

    function changePrice(uint registryId, uint price) public whenNotPaused() onlyRealtyOwner(registryId) returns (uint) {
        require(price >= 0, "Method called with an invalid price");
        idToRealty[registryId].price = price;
        emit RealtyPriceUpdated(registryId, price);
        return price;
    }

    function setAvailable(uint registryId) public whenNotPaused() onlyRealtyOwner(registryId) {
        RealtyState currentState = idToRealty[registryId].state;
        require(currentState != RealtyState.Available, "Realty state already available");
        idToRealty[registryId].state = RealtyState.Available;
        emit RealtyStateChanged(registryId, RealtyState.Available);
    }

    function setNotAvailable(uint registryId) public whenNotPaused() onlyRealtyOwner(registryId) {
        RealtyState currentState = idToRealty[registryId].state;
        require(currentState != RealtyState.NotAvailable, "Realty state already not available");
        idToRealty[registryId].state = RealtyState.NotAvailable;
        emit RealtyStateChanged(registryId, RealtyState.Available);
    }

    function _transferOwner(
        address from,
        address to,
        uint registryId
    ) private {
        require(from != address(0), "Method called with the zero address");
        require(to != address(0), "Method called with the zero address");
        require(ownerOf[registryId] != address(0), "Realty is not registered");

        _deregister(registryId);
        _register(registryId, to);

        idToRealty[registryId].state = RealtyState.NotAvailable;

        emit RealtyTransferred(registryId, from, to);
    }

    function _register(uint registryId, address owner) private {
        ownerOf[registryId] = owner;

        uint[] storage previousRealtyOwned = realtyOwned[owner];
        uint index = previousRealtyOwned.length;

        previousRealtyOwned.push(registryId);

        indexOfRealty[registryId] = index;

        emit RegistrationAdded(registryId, owner);

        totalRegistrations++;
    }

    function _deregister(uint registryId) private {
        address previousOwner = ownerOf[registryId];
        uint index = indexOfRealty[registryId];

        uint[] storage ownedAssets = realtyOwned[previousOwner];

        ownedAssets[index] = ownedAssets[ownedAssets.length - 1];

        ownedAssets.pop();

        delete ownerOf[registryId];
        delete idToRealty[registryId];
        delete indexOfRealty[registryId];

        totalRegistrations--;
    }
}
