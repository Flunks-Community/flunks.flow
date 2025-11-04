import SemesterZero from 0x807c3d470888cc48

/// Transaction: Start the Halloween GumDrop
/// For testing - creates a drop for ALL Flunks holders
/// 
/// Arguments:
/// - dropId: Unique identifier for this drop (e.g., "halloween-2025")
/// - gumAmount: Amount of GUM per claim (e.g., 100)
/// - durationHours: How long the drop is active (e.g., 72 for 3 days)

transaction(dropId: String, gumAmount: UFix64, durationHours: UFix64) {
    
    let adminRef: &SemesterZero.Admin
    
    prepare(signer: auth(Storage) &Account) {
        // Borrow admin capability
        self.adminRef = signer.storage.borrow<&SemesterZero.Admin>(
            from: SemesterZero.AdminStoragePath
        ) ?? panic("Could not borrow Admin reference from storage")
    }
    
    execute {
        // For testing, just make the admin's wallet eligible
        // In production, you'd query all Flunks holders from your backend
        let eligibleAddresses: [Address] = [0x807c3d470888cc48, 0xe327216d843357f1, 0x83a8d8f1c2438cd8]
        
        let durationSeconds = durationHours * 3600.0 // Convert hours to seconds
        
        // Create the drop
        self.adminRef.createGumDrop(
            dropId: dropId,
            eligibleAddresses: eligibleAddresses,
            amount: gumAmount,
            durationSeconds: durationSeconds
        )
        
        log("🎃 Halloween GumDrop created!")
        log("Drop ID: ".concat(dropId))
        log("GUM per claim: ".concat(gumAmount.toString()))
        log("Duration: ".concat(durationHours.toString()).concat(" hours"))
        log("Eligible users: ".concat(eligibleAddresses.length.toString()))
    }
}
