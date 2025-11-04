import TestPumpkinDrop420 from 0x807c3d470888cc48

/// Admin Transaction: Create a new GumDrop (72-hour claim window) on MAINNET
/// 
/// Usage:
/// flow transactions send cadence/transactions/admin-create-gum-drop-mainnet.cdc \
///   --arg String:"halloween-2025" \
///   --arg UFix64:"100.0" \
///   --arg UFix64:"259200.0" \
///   --args-json '[["0x807c3d470888cc48"]]' \
///   --signer mainnet-account \
///   --network mainnet
///
/// Arguments:
/// - dropId: Unique identifier for this drop (e.g., "halloween-2025")
/// - amount: Amount of GUM each user gets (e.g., 100.0)
/// - durationSeconds: Duration in seconds (259200 = 72 hours)
/// - eligibleAddresses: Array of addresses eligible to claim

transaction(
    dropId: String,
    eligibleAddresses: [Address],
    amount: UFix64,
    durationSeconds: UFix64
) {
    
    let adminRef: &TestPumpkinDrop420.Admin
    
    prepare(signer: auth(Storage) &Account) {
        // Borrow admin capability
        self.adminRef = signer.storage.borrow<&TestPumpkinDrop420.Admin>(
            from: TestPumpkinDrop420.AdminStoragePath
        ) ?? panic("Could not borrow Admin reference from storage")
    }
    
    execute {
        // Create the GumDrop
        self.adminRef.createGumDrop(
            dropId: dropId,
            eligibleAddresses: eligibleAddresses,
            amount: amount,
            durationSeconds: durationSeconds
        )
        
        log("GumDrop created successfully!")
        log("Drop ID: ".concat(dropId))
        log("Amount per claim: ".concat(amount.toString()))
        log("Duration: ".concat(durationSeconds.toString()).concat(" seconds"))
        log("Eligible addresses: ".concat(eligibleAddresses.length.toString()))
    }
}
