pragma solidity ^0.6.2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Pausable.sol';


/// @title A registry for Realty
/// @author https://github.com/andytcf/
/// @notice This contract is used to register and transfer Realty from owners
/// @dev The contract is owned by an EOA who is considered the super owner using openzeppellin's Ownable.sol
contract RealtyRegistry is Ownable, Pausable {
    /* Add the Address library for the address type */
    using Address for address;

    /// @notice This event is emitted when a registration is added
    /// @param registryId The registryId assigned to the realty
    /// @param owner The assigned owner of the realty added
    event RegistrationAdded(uint indexed registryId, address owner);

    /// @notice This event is emitted when a registration is removed
    /// @param registryId The registryId removed from the registry
    event RegistrationRemoved(uint indexed registryId);

    /// @notice This event is emitted when a transfer occurs
    /// @param registryId The realty that was transferred
    /// @param from The original owner
    /// @param to The new owner
    event RealtyTransferred(uint indexed registryId, address from, address to);

    /// @notice This event is emitted when a purchased occurs
    /// @param registryId The realty that was purchased
    /// @param price The purchased price
    /// @param purchaser The account who purchased it
    event RealtyPurchased(uint indexed registryId, uint price, address purchaser);

    /// @notice This event is emitted when a price update occurs
    /// @param registryId The realty that was updated
    /// @param price The new purchase price
    event RealtyPriceUpdated(uint indexed registryId, uint price);

    /// @notice This event is emitted when a realty state change occurs
    /// @param registryId The realty state that was changed
    /// @param newState The new state that the realty is set to "Available" "NotAvailable"
    event RealtyStateChanged(uint indexed registryId, RealtyState newState);

    /// @notice This event is emitted when funds are deposited into a users account
    /// @param amount The value deposited
    /// @param owner The address which the funds were transferred to
    event FundsDeposited(uint amount, address indexed owner);

    /// @notice This event is emitted when funds are withdrawn from the contract
    /// @param amount The value withdrawn
    /// @param withdrawer The address which the funds were transferred to
    event FundsWithdrawn(uint amount, address indexed withdrawer);

    /* Mapping Realty id to Realty struct  */
    mapping(uint => Realty) public idToRealty;
    /* Mapping Realty id to their owner  */
    mapping(uint => address) public ownerOf;
    /* Mapping address to their owned Realties */
    mapping(address => uint[]) public realtyOwned;
    /* Mapping the index of where the Realty is stored within realtyOwned */
    mapping(uint => uint) public indexOfRealty;
    /* Mapping address to their ether balance */
    mapping(address => uint) public balance;

    /* The total count of registrations */
    uint public totalRegistrations;
    /* The current unique id used for registering a Realty */
    uint public currentID;
    /* The time when this registry was created */
    uint public registryCreated;

    /* Enum which contains the states that a Realty can be in */
    enum RealtyState {Available, NotAvailable}

    /* Stores the attributes of a Realty */
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

    /**
     * @dev Constructor
     * @notice Initializes the registryCreated state value
     */
    constructor() public {
        registryCreated = now;
    }

    //-----------------------------------------------------------------
    // Modifiers
    //-----------------------------------------------------------------

    /**
     * @dev Modified used before owned Realty mutative functions
     * @param registryId The registryId to check the owner of
     */
    modifier onlyRealtyOwner(uint registryId) {
        require(ownerOf[registryId] == msg.sender, 'Msg sender is not the owner of the Realty');
        _;
    }

    //-----------------------------------------------------------------
    // Public Mutative Functions
    //-----------------------------------------------------------------

    /**
     * @notice A function only used by the registry owner to register a new Realty
     * @dev The registryId is automatically generated by the currentID state variable
     * @param streetName The street name of the Realty
     * @param postCode The post code/zip code of the Realty
     * @param city The city the Realty is located in
     * @param country The country the Realty is located in
     * @param realtyType The type of realtyType etc. "Commerical" "Business"
     * @param price The initial value of the Realty
     * @param owner The initial owner of the Realty on registration.
     */
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

    /**
     * @notice A function only used by the registry owner to deregister an existing Realty
     * @param registryId The id of the Realty to deregister
     */
    function deregister(uint registryId) public whenNotPaused() onlyOwner() {
        require(ownerOf[registryId] != address(0), 'Realty is not registered');
        _deregister(registryId);
    }

    /**
     * @notice Function used by a purchaser to purchase an available Realty
     * @dev Function is payable
     * @param registryId The id of the Realty to purchase
     */
    function purchaseRegistration(uint registryId) public payable whenNotPaused() {
        Realty memory currentRealty = idToRealty[registryId];
        require(currentRealty.state == RealtyState.Available, 'Realty is not for sale');
        require(msg.value >= currentRealty.price, 'Insufficient value sent to purchase realty');

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

    /**
     * @notice Function which allows a user to withdraw any fund that are escrowed in the contract
     */
    function withdrawFunds() public {
        require(balance[msg.sender] > 0, 'Insufficient funds to withdraw');
        uint amount = balance[msg.sender];
        balance[msg.sender] = 0;
        msg.sender.transfer(amount);
        emit FundsWithdrawn(amount, msg.sender);
    }

    /**
     * @notice Privileged function which allows the Realty owner to change the listing price
     * @param registryId The id of the Realty to change
     * @param price The new price to set the Realty to
     */
    function changePrice(uint registryId, uint price)
        public
        whenNotPaused()
        onlyRealtyOwner(registryId)
        returns (uint)
    {
        require(price >= 0, 'Method called with an invalid price');
        idToRealty[registryId].price = price;
        emit RealtyPriceUpdated(registryId, price);
        return price;
    }

    /**
     * @notice Privileged function which allows the Realty owner to change the availability of the listing
     * @dev The RealtyState is automatically toggled to available or not available depending on previous state
     * @param registryId The id of the Realty to change
     */
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

    //-----------------------------------------------------------------
    // Private Functions
    //-----------------------------------------------------------------

    function _transferOwner(
        address from,
        address to,
        uint registryId
    ) private {
        require(from != address(0), 'Method called with the zero address');
        require(to != address(0), 'Method called with the zero address');
        require(ownerOf[registryId] != address(0), 'Realty is not registered');

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
