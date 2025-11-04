import SemesterZero from "../contracts/SemesterZero_Hackathon.cdc"

/// Admin: Register overachiever completion for Chapter 5
transaction(userAddress: Address) {
    
    let adminRef: &SemesterZero.Admin
    
    prepare(admin: auth(Storage) &Account) {
        self.adminRef = admin.storage.borrow<&SemesterZero.Admin>(
            from: SemesterZero.AdminStoragePath
        ) ?? panic("No admin resource found")
    }
    
    execute {
        self.adminRef.registerOverachieverCompletion(userAddress: userAddress)
        
        log("Overachiever completion registered for: ".concat(userAddress.toString()))
    }
}
