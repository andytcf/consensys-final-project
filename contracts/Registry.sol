pragma solidity ^0.6.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";


contract Registry is Ownable, Pausable {
    using Address for address;

    event RegistrationAdded(uint indexed registryId, address owner);
    event RegistrationRemoved(uint indexed registryId);

    event RealtyTransferred(uint indexed registryId, address from, address to);
    event RealtyPurchased(uint indexed registryId, uint price, address purchaser);
    event RealtyPriceUpdated(uint indexed registryId, uint price);
    event RealtyStateChanged(uint indexed registryId, RealtyState newState);

    event FundsDeposited(uint amount, address indexed sender);
    event FundsWithdrawn(uint amount, address indexed withdrawer);

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
        uint id = _register(streetName, postCode, city, country, realtyType, price, owner, currentID);

        currentID++;

        return id;
    }

    function deregister(uint registryId) public whenNotPaused() onlyOwner() {
        require(ownerOf[registryId] != address(0), "Realty is not registered");
        _deregister(registryId);
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
            uint excessValue = msg.value - currentRealty.price;
            balance[purchaser] = balance[purchaser] + msg.value - currentRealty.price;
            emit FundsDeposited(excessValue, purchaser);
        }

        emit FundsDeposited(purchasedPrice, currentOwner);
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

    function changeAvailability(uint registryId) public whenNotPaused() onlyRealtyOwner(registryId) {
        RealtyState currentState = idToRealty[registryId].state;

        if (currentState == RealtyState.Available) {
            idToRealty[registryId].state = RealtyState.NotAvailable;
        } else {
            idToRealty[registryId].state = RealtyState.Available;
        }

        RealtyState newState = idToRealty[registryId].state;

        emit RealtyStateChanged(registryId, newState);
    }

    function _transferOwner(
        address from,
        address to,
        uint registryId
    ) private {
        require(from != address(0), "Method called with the zero address");
        require(to != address(0), "Method called with the zero address");
        require(ownerOf[registryId] != address(0), "Realty is not registered");

        _removeRealtyFromOwned(registryId);
        _addRealtyToOwned(registryId, to);
        ownerOf[registryId] = to;

        idToRealty[registryId].state = RealtyState.NotAvailable;

        emit RealtyTransferred(registryId, from, to);
    }

    function _register(
        string memory streetName,
        string memory postCode,
        string memory city,
        string memory country,
        string memory realtyType,
        uint price,
        address owner,
        uint registryId
    ) private returns (uint) {
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
        _addRealtyToOwned(registryId, owner);

        ownerOf[registryId] = owner;

        emit RegistrationAdded(registryId, owner);

        totalRegistrations++;

        return registryId;
    }

    function _deregister(uint registryId) private {
        _removeRealtyFromOwned(registryId);

        delete ownerOf[registryId];

        delete idToRealty[registryId];

        emit RegistrationRemoved(registryId);

        totalRegistrations--;
    }

    function _removeRealtyFromOwned(uint registryId) private {
        address previousOwner = ownerOf[registryId];
        uint index = indexOfRealty[registryId];

        uint[] storage ownedAssets = realtyOwned[previousOwner];

        ownedAssets[index] = ownedAssets[ownedAssets.length - 1];

        ownedAssets.pop();
        delete indexOfRealty[registryId];
    }

    function _addRealtyToOwned(uint registryId, address newOwner) private {
        uint[] storage previousRealtyOwned = realtyOwned[newOwner];
        uint index = previousRealtyOwned.length;

        previousRealtyOwned.push(registryId);

        indexOfRealty[registryId] = index;
    }
}
