# Addressable Security Issues

## Denial Of Service Attack

In the Registry.sol contract, when either a purchaser or seller transacts Realty, their excess amount (purchaser) and their earnings (seller) are kept in the contract state as a mapping called `balance`. If the contract where to handle the `transfer` of funds directly within the `purchaseRegistration` function, a malicious user could call the function with a malicious contract which reverts each time, preventing the contract from being usable as users would not be able to transfer/purchase registrations anymore.

Therefore, in Registry.sol, the withdrawal pattern is opted. Users would need to call a separate function to withdraw their funds that are stored within the contract state

## Reentrancy Attack

In `withdrawFunds` the balance is assigned to a variable and then the balance state is then set to 0 to prevent a user from being able to perform a reentrancy attack and repeatedly withdraw funds that they do not have.
