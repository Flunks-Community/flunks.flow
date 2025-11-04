import SemesterZero from 0xce9dd43888d99574

/// Admin marks a user as complete for Chapter 5 (both slacker and overachiever)
/// User must have collection set up first
transaction(userAddress: Address) {
    let adminRef: &SemesterZero.Admin
    
    prepare(signer: auth(BorrowValue) &Account) {
        self.adminRef = signer.storage.borrow<&SemesterZero.Admin>(
            from: SemesterZero.AdminStoragePath
        ) ?? panic("Could not borrow admin reference")
    }
    
    execute {
        // Mark user as having completed both objectives
        self.adminRef.registerSlackerCompletion(userAddress: userAddress)
        log("✅ Marked slacker complete for: ".concat(userAddress.toString()))
        
        self.adminRef.registerOverachieverCompletion(userAddress: userAddress)
        log("✅ Marked overachiever complete for: ".concat(userAddress.toString()))
        
        log("🎯 User is now eligible for Chapter 5 NFT airdrop!")
    }
}
