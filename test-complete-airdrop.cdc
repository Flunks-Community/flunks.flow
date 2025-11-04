import SemesterZero from 0xce9dd43888d99574

/// Test airdrop transaction - marks user as complete and airdrops Chapter 5 NFT
/// This is for testing purposes only
transaction(recipientAddress: Address) {
    let adminRef: &SemesterZero.Admin
    
    prepare(signer: auth(BorrowValue) &Account) {
        self.adminRef = signer.storage.borrow<&SemesterZero.Admin>(
            from: SemesterZero.AdminStoragePath
        ) ?? panic("Could not borrow admin reference")
    }
    
    execute {
        // First, mark the user as having completed both slacker and overachiever
        self.adminRef.registerSlackerCompletion(userAddress: recipientAddress)
        self.adminRef.registerOverachieverCompletion(userAddress: recipientAddress)
        
        log("✅ Marked user as complete")
        
        // Now airdrop the Chapter 5 NFT
        self.adminRef.airdropChapter5NFT(userAddress: recipientAddress)
        
        log("✅ Chapter 5 NFT airdropped successfully!")
        log("Recipient: ".concat(recipientAddress.toString()))
    }
}
