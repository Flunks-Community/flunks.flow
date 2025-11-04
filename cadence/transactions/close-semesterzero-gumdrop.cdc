import SemesterZero from 0x807c3d470888cc48

/// Admin transaction to close the active GumDrop
transaction {
    
    let adminRef: &SemesterZero.Admin
    
    prepare(signer: auth(Storage) &Account) {
        self.adminRef = signer.storage.borrow<&SemesterZero.Admin>(
            from: SemesterZero.AdminStoragePath
        ) ?? panic("Could not borrow Admin resource")
    }
    
    execute {
        self.adminRef.closeGumDrop()
        log("GumDrop closed!")
    }
}
