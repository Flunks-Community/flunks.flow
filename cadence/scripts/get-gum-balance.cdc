import GUM from 0x807c3d470888cc48
import FungibleToken from 0xf233dcee88fe0abe

access(all) fun main(accountAddress: Address): UFix64 {
    // Get the account at the specified address
    let account = getAccount(accountAddress)

    // Attempt to borrow a reference to the GUM Vault's Balance interface
    let balanceRef = account
        .capabilities.borrow<&GUM.Vault>(GUM.VaultBalancePublicPath)

    // If the vault is set up, return the balance; otherwise, return 0
    if let ref = balanceRef {
        return ref.balance
    } else {
        return 0.0
    }
}