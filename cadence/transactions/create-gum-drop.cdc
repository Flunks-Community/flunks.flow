import SemesterZero from "../contracts/SemesterZero_Hackathon.cdc"

/// Admin: Create a GumDrop with 48-hour claim window
/// Example: 172800.0 seconds = 48 hours
transaction(dropId: String, eligibleAddresses: [Address], amount: UFix64, durationSeconds: UFix64) {
    
    let adminRef: &SemesterZero.Admin
    
    prepare(admin: auth(Storage) &Account) {
        self.adminRef = admin.storage.borrow<&SemesterZero.Admin>(
            from: SemesterZero.AdminStoragePath
        ) ?? panic("No admin resource found")
    }
    
    execute {
        self.adminRef.createGumDrop(
            dropId: dropId,
            eligibleAddresses: eligibleAddresses,
            amount: amount,
            durationSeconds: durationSeconds
        )
        
        log("GumDrop created: ".concat(dropId))
        log("Eligible users: ".concat(eligibleAddresses.length.toString()))
        log("Amount: ".concat(amount.toString()))
        log("Duration: ".concat(durationSeconds.toString()).concat(" seconds"))
    }
}
