import SemesterZero from 0xb97ea2274b0ae5d2

/// Admin Transaction: Create a new GumDrop (72-hour claim window)
/// 
/// Usage:
/// flow transactions send cadence/transactions/admin-create-gum-drop.cdc \
///   --arg String:"halloween-2025" \
///   --arg UFix64:"100.0" \
///   --arg UFix64:"259200.0" \
///   --args-json '[["0x50b39b...", "0x123abc..."]]' \
///   --signer Flunks2.0 \
///   --network testnet
///
/// Arguments:
/// - dropId: Unique identifier for this drop (e.g., "halloween-2025")
/// - amount: Amount of GUM each user gets (e.g., 100.0)
/// - durationSeconds: Duration in seconds (259200 = 72 hours)
/// - eligibleAddresses: Array of addresses eligible to claim

transaction(
    dropId: String,
    amount: UFix64,
    durationSeconds: UFix64,
    eligibleAddresses: [Address]
) {
    
    let adminRef: &SemesterZero.Admin
    
    prepare(signer: auth(Storage) &Account) {
        // Borrow admin capability
        self.adminRef = signer.storage.borrow<&SemesterZero.Admin>(
            from: SemesterZero.AdminStoragePath
        ) ?? panic("Could not borrow Admin resource - are you the contract owner?")
    }
    
    execute {
        // Create the GumDrop
        self.adminRef.createGumDrop(
            dropId: dropId,
            eligibleAddresses: eligibleAddresses,
            amount: amount,
            durationSeconds: durationSeconds
        )
        
        log("✅ GumDrop created!")
        log("Drop ID: ".concat(dropId))
        log("Amount per claim: ".concat(amount.toString()))
        log("Duration: ".concat(durationSeconds.toString()).concat(" seconds"))
        log("Eligible users: ".concat(eligibleAddresses.length.toString()))
    }
    
    post {
        SemesterZero.activeGumDrop != nil: "GumDrop was not created successfully"
    }
}
