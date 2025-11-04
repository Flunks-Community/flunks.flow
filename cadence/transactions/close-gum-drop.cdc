import SemesterZero from "../contracts/SemesterZero_Hackathon.cdc"

/// Admin: Close the active GumDrop
transaction {
    
    let adminRef: &SemesterZero.Admin
    
    prepare(admin: auth(Storage) &Account) {
        self.adminRef = admin.storage.borrow<&SemesterZero.Admin>(
            from: SemesterZero.AdminStoragePath
        ) ?? panic("No admin resource found")
    }
    
    execute {
        self.adminRef.closeGumDrop()
        
        log("GumDrop closed")
    }
}
