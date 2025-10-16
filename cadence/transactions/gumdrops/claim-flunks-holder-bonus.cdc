// User transaction - claims on-chain bonus for holding Flunks NFTs
// Verifies actual NFT ownership, gives 2 GUM per Flunks owned

import GUMDrops from "../../contracts/GUMDrops.cdc"
import Flunks from "../../contracts/Flunks.cdc"
import GUM from "../../contracts/GUM.cdc"
import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"

transaction {
    let gumReceiver: &{FungibleToken.Receiver}
    let flunksCollection: &{NonFungibleToken.CollectionPublic}
    
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
        
        // Get user's Flunks collection
        self.flunksCollection = signer.capabilities.get<&{NonFungibleToken.CollectionPublic}>(
            /public/FlunksCollection
        ).borrow() ?? panic("Could not borrow Flunks collection")
    }
    
    execute {
        // Get count of Flunks owned
        let flunksOwned = self.flunksCollection.getIDs().length
        
        if flunksOwned == 0 {
            panic("You don't own any Flunks NFTs")
        }
        
        // Claim bonus (2 GUM per Flunks)
        let bonusVault <- GUMDrops.claimFlunksHolderBonus(claimer: self.flunksCollection)
        
        let amountClaimed = bonusVault.balance
        self.gumReceiver.deposit(from: <-bonusVault)
        
        log("Claimed ".concat(amountClaimed.toString()).concat(" GUM for holding ").concat(flunksOwned.toString()).concat(" Flunks!"))
    }
}
