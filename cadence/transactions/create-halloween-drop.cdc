import SemesterZero from "../contracts/SemesterZero.cdc"

/// Admin: Create Halloween drop with list of eligible users
/// This just marks who CAN claim - no GUM transferred yet!
transaction(dropId: String, eligibleAddresses: [Address], amount: UFix64) {
    
    let adminRef: &SemesterZero.Admin
    
    prepare(admin: auth(Storage) &Account) {
        self.adminRef = admin.storage.borrow<&SemesterZero.Admin>(
            from: SemesterZero.AdminStoragePath
        ) ?? panic("No admin resource found")
    }
    
    execute {
        self.adminRef.createHalloweenDrop(
            dropId: dropId,
            eligibleAddresses: eligibleAddresses,
            amount: amount
        )
        
        log("Halloween drop created: ".concat(dropId))
        log("Eligible users: ".concat(eligibleAddresses.length.toString()))
        log("Amount: ".concat(amount.toString()))
    }
}
