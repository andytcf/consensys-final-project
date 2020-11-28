# Addressable Design Patterns

## Pausable/Circuit Breaker

Registry.sol inherits OpenZepellin's Pausable contract which exposes a `whenNotPaused` modifier, this modifier is then used throughout the Registry.sol contract to halt the usage of the contract in the case of any issues. However even when the contract is paused, users can withdraw their funds.

## Restricting Access

Registry.sol inehrits OpenZepellin's Ownable contract which automatically assigns the contract deployer as the owner. It also exposes the `onlyOwner` modifier which is used to restrict the access to admin functions such as registering and deregistering a Realty. This pattern was implemented to prevent the listing of duplicated Realty and to maintain a uniform and somewhat centralized system of registration. In the future, work can be done to relinquish this centralization and instead assign it to a multisig wallet which is a registry council whom determine what is a valid registation and not.
