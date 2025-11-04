import SemesterZero from "../contracts/SemesterZero.cdc"

/// Admin: Mark user as claimed after Supabase GUM has been added
/// Called by API after user clicks "Claim" and Supabase is updated
transaction(userAddress: Address) {
    
    let adminRef: &SemesterZero.Admin
    
    prepare(admin: auth(Storage) &Account) {
        self.adminRef = admin.storage.borrow<&SemesterZero.Admin>(
            from: SemesterZero.AdminStoragePath
        ) ?? panic("No admin resource found")
    }
    
    execute {
        // Verify eligibility
        assert(
            SemesterZero.isEligibleForHalloween(userAddress),
            message: "User not eligible for Halloween drop"
        )
        assert(
            !SemesterZero.hasClaimedHalloween(userAddress),
            message: "User already claimed Halloween drop"
        )
        
        self.adminRef.markHalloweenClaimed(userAddress)
        
        log("User marked as claimed: ".concat(userAddress.toString()))
    }
}
