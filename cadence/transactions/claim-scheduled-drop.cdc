// Claim from a scheduled drop by dropID

import GUMDrops from "../contracts/GUMDrops.cdc"
import GUM from "../contracts/GUM.cdc"
import FungibleToken from "../contracts/FungibleToken.cdc"

transaction(dropID: UInt64) {
    prepare(signer: auth(Storage, Capabilities, BorrowValue, SaveValue) &Account) {
        
        // Setup GUM vault if needed
        if signer.storage.type(at: GUM.VaultStoragePath) == nil {
            let vault <- GUM.createEmptyVault(vaultType: Type<@GUM.Vault>())
            signer.storage.save(<-vault, to: GUM.VaultStoragePath)
            
            let vaultCap = signer.capabilities.storage.issue<&GUM.Vault>(GUM.VaultStoragePath)
            signer.capabilities.publish(vaultCap, at: GUM.VaultBalancePublicPath)
            
            let receiverCap = signer.capabilities.storage.issue<&{FungibleToken.Receiver}>(GUM.VaultStoragePath)
            signer.capabilities.publish(receiverCap, at: GUM.VaultReceiverPublicPath)
        }
        
        // Claim from scheduled drop
        GUMDrops.claimScheduledDrop(claimer: signer, dropID: dropID)
    }

    execute {
        log("Claimed from drop ID: ".concat(dropID.toString()))
    }
}
