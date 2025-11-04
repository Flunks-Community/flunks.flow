import SemesterZero from 0xb97ea2274b0ae5d2

/// Admin Transaction: Mark user as claimed (called after GUM added to Supabase)
/// 
/// Usage:
/// flow transactions send cadence/transactions/admin-mark-gum-claimed.cdc \
///   --arg Address:"0x50b39b..." \
///   --signer Flunks2.0 \
///   --network testnet

transaction(userAddress: Address) {
    
    let adminRef: &SemesterZero.Admin
    
    prepare(signer: auth(Storage) &Account) {
        // Borrow admin capability
        self.adminRef = signer.storage.borrow<&SemesterZero.Admin>(
            from: SemesterZero.AdminStoragePath
        ) ?? panic("Could not borrow Admin resource - are you the contract owner?")
    }
    
    execute {
        // Mark user as claimed
        self.adminRef.markGumClaimed(user: userAddress)
        
        log("✅ User marked as claimed: ".concat(userAddress.toString()))
    }
}
