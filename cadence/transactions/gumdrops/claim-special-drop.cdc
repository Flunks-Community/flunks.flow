// User transaction - claims from a special event drop
// Admin must have created the drop first

import GUMDrops from "../../contracts/GUMDrops.cdc"
import Flunks from "../../contracts/Flunks.cdc"
import GUM from "../../contracts/GUM.cdc"
import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"

transaction(dropID: UInt64) {
    let gumReceiver: &{FungibleToken.Receiver}
    let flunksCollection: &{NonFungibleToken.CollectionPublic}?
    
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Get user's GUM vault receiver
        if let vaultCap = signer.capabilities.get<&GUM.Vault>(/public/GUMVault) {
            self.gumReceiver = vaultCap.borrow() ?? panic("Could not borrow GUM receiver")
        } else {
            // Setup GUM vault if not exists
            if signer.storage.borrow<&GUM.Vault>(from: /storage/GUMVault) == nil {
                signer.storage.save(<-GUM.createEmptyVault(vaultType: Type<@GUM.Vault>()), to: /storage/GUMVault)
                
                let receiverCap = signer.capabilities.storage.issue<&GUM.Vault>(/storage/GUMVault)
                signer.capabilities.publish(receiverCap, at: /public/GUMVault)
            }
            
            let vaultCap = signer.capabilities.get<&GUM.Vault>(/public/GUMVault)
            self.gumReceiver = vaultCap.borrow() ?? panic("Could not borrow GUM receiver after setup")
        }
        
        // Try to get Flunks collection (may be required for some drops)
        self.flunksCollection = signer.capabilities.get<&{NonFungibleToken.CollectionPublic}>(
            /public/FlunksCollection
        ).borrow()
    }
    
    execute {
        // Claim from special drop
        let claimedVault <- GUMDrops.claimSpecialDrop(
            dropID: dropID,
            claimer: self.flunksCollection
        )
        
        let amountClaimed = claimedVault.balance
        self.gumReceiver.deposit(from: <-claimedVault)
        
        log("Claimed ".concat(amountClaimed.toString()).concat(" GUM from special drop #").concat(dropID.toString()))
    }
}
