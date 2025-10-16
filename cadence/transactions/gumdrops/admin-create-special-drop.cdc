// Admin transaction - creates a special event drop
// Example: Halloween event, milestone celebration, etc.

import GUMDrops from "../../contracts/GUMDrops.cdc"
import GUM from "../../contracts/GUM.cdc"
import FungibleToken from "../../contracts/FungibleToken.cdc"

transaction(
    totalAmount: UFix64,
    amountPerClaim: UFix64,
    startTime: UFix64,
    endTime: UFix64,
    requiresFlunks: Bool,
    description: String
) {
    let admin: &GUMDrops.Admin
    
    prepare(signer: auth(Storage, BorrowValue) &Account) {
        self.admin = signer.storage.borrow<&GUMDrops.Admin>(
            from: GUMDrops.AdminStoragePath
        ) ?? panic("Could not borrow admin resource")
    }
    
    execute {
        // Create the special drop
        let dropID = self.admin.createSpecialDrop(
            totalAmount: totalAmount,
            amountPerClaim: amountPerClaim,
            startTime: startTime,
            endTime: endTime,
            requiresFlunks: requiresFlunks,
            description: description
        )
        
        log("Created special drop #".concat(dropID.toString()).concat(": ").concat(description))
        log("Total pool: ".concat(totalAmount.toString()).concat(" GUM"))
        log("Per claim: ".concat(amountPerClaim.toString()).concat(" GUM"))
        log("Requires Flunks: ".concat(requiresFlunks.toString()))
    }
}
