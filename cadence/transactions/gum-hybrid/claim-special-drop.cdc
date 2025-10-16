// Claim from a special drop

import GumDropsHybrid from "../../contracts/GumDropsHybrid.cdc"
import Flunks from "../../contracts/Flunks.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"

transaction(dropID: UInt64) {
    let gumAccount: auth(GumDropsHybrid.GumAccount) &GumDropsHybrid.GumAccount
    let flunksCollection: &{NonFungibleToken.CollectionPublic}?
    
    prepare(signer: auth(Storage, BorrowValue) &Account) {
        // Get GUM account
        self.gumAccount = signer.storage.borrow<auth(GumDropsHybrid.GumAccount) &GumDropsHybrid.GumAccount>(
            from: GumDropsHybrid.GumAccountStoragePath
        ) ?? panic("No GUM account found. Run setup-gum-account.cdc first")
        
        // Try to get Flunks collection (may be required for some drops)
        self.flunksCollection = signer.capabilities.get<&{NonFungibleToken.CollectionPublic}>(
            Flunks.CollectionPublicPath
        ).borrow()
    }
    
    execute {
        // Get drop info
        let dropInfo = GumDropsHybrid.getSpecialDropInfo(dropID: dropID)
            ?? panic("Drop not found")
        
        log("Claiming from drop: ".concat(dropInfo.description))
        log("Amount per claim: ".concat(dropInfo.amountPerClaim.toString()).concat(" GUM"))
        
        // Claim from special drop
        GumDropsHybrid.claimSpecialDrop(
            dropID: dropID,
            claimer: self.gumAccount,
            flunksCollection: self.flunksCollection
        )
        
        let newBalance = self.gumAccount.getInfo().balance
        log("Claimed successfully! New balance: ".concat(newBalance.toString()).concat(" GUM"))
    }
}
