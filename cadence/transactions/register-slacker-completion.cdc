import SemesterZero from "../contracts/SemesterZero_Hackathon.cdc"

/// Admin: Register slacker completion for Chapter 5
transaction(userAddress: Address) {
    
    let adminRef: &SemesterZero.Admin
    
    prepare(admin: auth(Storage) &Account) {
        self.adminRef = admin.storage.borrow<&SemesterZero.Admin>(
            from: SemesterZero.AdminStoragePath
        ) ?? panic("No admin resource found")
    }
    
    execute {
        self.adminRef.registerSlackerCompletion(userAddress: userAddress)
        
        log("Slacker completion registered for: ".concat(userAddress.toString()))
    }
}
