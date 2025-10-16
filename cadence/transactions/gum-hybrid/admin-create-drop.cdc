// Admin: Create a special drop

import GumDropsHybrid from "../../contracts/GumDropsHybrid.cdc"

transaction(
    totalAmount: UFix64,
    amountPerClaim: UFix64,
    startTime: UFix64,
    endTime: UFix64,
    requiresFlunks: Bool,
    description: String
) {
    let admin: &GumDropsHybrid.Admin
    
    prepare(signer: auth(Storage, BorrowValue) &Account) {
        self.admin = signer.storage.borrow<&GumDropsHybrid.Admin>(
            from: GumDropsHybrid.AdminStoragePath
        ) ?? panic("Not authorized - admin only")
    }
    
    execute {
        let dropID = self.admin.createSpecialDrop(
            totalAmount: totalAmount,
            amountPerClaim: amountPerClaim,
            startTime: startTime,
            endTime: endTime,
            requiresFlunks: requiresFlunks,
            description: description
        )
        
        log("✨ Created special drop #".concat(dropID.toString()))
        log("📦 Total pool: ".concat(totalAmount.toString()).concat(" GUM"))
        log("💎 Per claim: ".concat(amountPerClaim.toString()).concat(" GUM"))
        log("🎯 Requires Flunks: ".concat(requiresFlunks ? "Yes" : "No"))
        log("📝 Description: ".concat(description))
        log("⏰ Active from ".concat(startTime.toString()).concat(" to ").concat(endTime.toString()))
    }
}
