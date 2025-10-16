// Admin: Sync user's Supabase balance to blockchain

import GumDropsHybrid from "../../contracts/GumDropsHybrid.cdc"

transaction(userAddress: Address, supabaseBalance: UFix64) {
    let admin: &GumDropsHybrid.Admin
    
    prepare(signer: auth(Storage, BorrowValue) &Account) {
        self.admin = signer.storage.borrow<&GumDropsHybrid.Admin>(
            from: GumDropsHybrid.AdminStoragePath
        ) ?? panic("Not authorized - admin only")
    }
    
    execute {
        self.admin.syncUserBalance(
            userAddress: userAddress,
            supabaseBalance: supabaseBalance
        )
        
        log("Synced ".concat(userAddress.toString()).concat(" balance to ").concat(supabaseBalance.toString()).concat(" GUM"))
    }
}
