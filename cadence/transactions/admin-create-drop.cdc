// Admin: Create a scheduled GUM drop
// Example: Airdrop to first 100 claimers

import GUMDrops from "../contracts/GUMDrops.cdc"

transaction(
    totalAmount: UFix64,
    amountPerClaim: UFix64,
    startTime: UFix64,
    endTime: UFix64?,
    requiresFlunks: Bool
) {
    
    let admin: &GUMDrops.Admin
    
    prepare(signer: auth(Storage, BorrowValue) &Account) {
        self.admin = signer.storage.borrow<&GUMDrops.Admin>(from: GUMDrops.AdminStoragePath)
            ?? panic("Could not borrow admin resource")
    }
    
    execute {
        let dropID = self.admin.createScheduledDrop(
            totalAmount: totalAmount,
            amountPerClaim: amountPerClaim,
            startTime: startTime,
            endTime: endTime,
            requiresFlunks: requiresFlunks
        )
        
        log("Created scheduled drop with ID: ".concat(dropID.toString()))
        log("Total amount: ".concat(totalAmount.toString()))
        log("Amount per claim: ".concat(amountPerClaim.toString()))
    }
}
