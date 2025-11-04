import SemesterZero from "../contracts/SemesterZero_Hackathon.cdc"

/// Admin: Mark user as claimed after GUM added to Supabase
/// Called by API after user clicks "Claim" and Supabase is updated
transaction(userAddress: Address) {
    
    let adminRef: &SemesterZero.Admin
    
    prepare(admin: auth(Storage) &Account) {
        self.adminRef = admin.storage.borrow<&SemesterZero.Admin>(
            from: SemesterZero.AdminStoragePath
        ) ?? panic("No admin resource found")
    }
    
    execute {
        // Verify user is eligible before marking claimed
        assert(
            SemesterZero.isEligibleForGumDrop(user: userAddress),
            message: "User not eligible for GumDrop"
        )
        assert(
            !SemesterZero.hasClaimedGumDrop(user: userAddress),
            message: "User already claimed GumDrop"
        )
        
        self.adminRef.markGumClaimed(user: userAddress)
        
        log("User marked as claimed: ".concat(userAddress.toString()))
    }
}
