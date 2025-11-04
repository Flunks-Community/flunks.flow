import SemesterZero from "../contracts/SemesterZero_Hackathon.cdc"

/// Admin: Airdrop Chapter 5 NFT to eligible user
/// User must have both slacker and overachiever complete
transaction(userAddress: Address) {
    
    let adminRef: &SemesterZero.Admin
    
    prepare(admin: auth(Storage) &Account) {
        self.adminRef = admin.storage.borrow<&SemesterZero.Admin>(
            from: SemesterZero.AdminStoragePath
        ) ?? panic("No admin resource found")
    }
    
    execute {
        self.adminRef.airdropChapter5NFT(userAddress: userAddress)
        
        log("Chapter 5 NFT airdropped to: ".concat(userAddress.toString()))
    }
}
