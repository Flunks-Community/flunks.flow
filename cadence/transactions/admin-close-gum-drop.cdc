import SemesterZero from 0xb97ea2274b0ae5d2

/// Admin Transaction: Close the active GumDrop
/// 
/// Usage:
/// flow transactions send cadence/transactions/admin-close-gum-drop.cdc \
///   --signer Flunks2.0 \
///   --network testnet

transaction() {
    
    let adminRef: &SemesterZero.Admin
    
    prepare(signer: auth(Storage) &Account) {
        // Borrow admin capability
        self.adminRef = signer.storage.borrow<&SemesterZero.Admin>(
            from: SemesterZero.AdminStoragePath
        ) ?? panic("Could not borrow Admin resource - are you the contract owner?")
    }
    
    execute {
        // Close the active GumDrop
        self.adminRef.closeGumDrop()
        
        log("✅ GumDrop closed successfully")
    }
    
    post {
        SemesterZero.activeGumDrop == nil: "GumDrop was not closed successfully"
    }
}
