import TestPumpkinDrop420 from 0x807c3d470888cc48

/// Admin Transaction: Close the active GumDrop on MAINNET

transaction() {
    
    let adminRef: &TestPumpkinDrop420.Admin
    
    prepare(signer: auth(Storage) &Account) {
        // Borrow admin capability
        self.adminRef = signer.storage.borrow<&TestPumpkinDrop420.Admin>(
            from: TestPumpkinDrop420.AdminStoragePath
        ) ?? panic("Could not borrow Admin reference from storage")
    }
    
    execute {
        // Close the GumDrop
        self.adminRef.closeGumDrop()
        
        log("GumDrop closed successfully!")
    }
}
