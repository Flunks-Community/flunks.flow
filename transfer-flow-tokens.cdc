import FungibleToken from 0xf233dcee88fe0abe
import FlowToken from 0x1654653399040a61

transaction(recipient: Address, amount: UFix64) {
    let sentVault: @{FungibleToken.Vault}
    
    prepare(signer: auth(BorrowValue) &Account) {
        let vaultRef = signer.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(
            from: /storage/flowTokenVault
        ) ?? panic("Could not borrow reference to the owner's Vault!")
        
        self.sentVault <- vaultRef.withdraw(amount: amount)
    }
    
    execute {
        let receiverRef = getAccount(recipient).capabilities
            .borrow<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
            ?? panic("Could not borrow receiver reference to the recipient's Vault")
        
        receiverRef.deposit(from: <-self.sentVault)
    }
}
