import TestPumpkinDrop420 from 0x807c3d470888cc48

/// Transaction: Start the Halloween GumDrop
/// This should be scheduled via Flow Actions to run on October 31, 2025 at 6pm EST
/// 
/// Arguments:
/// - startTime: Unix timestamp when drop begins (e.g., 1730412000 for Oct 31, 2025 6pm EST)
/// - endTime: Unix timestamp when drop ends (startTime + 259200 for 72 hours)
/// - gumPerFlunk: Amount of GUM per Flunk NFT (e.g., 100)

transaction(startTime: UFix64, endTime: UFix64, gumPerFlunk: UInt64) {
    
    let adminRef: &TestPumpkinDrop420.Admin
    
    prepare(signer: auth(Storage) &Account) {
        // Borrow admin capability
        self.adminRef = signer.storage.borrow<&TestPumpkinDrop420.Admin>(
            from: TestPumpkinDrop420.AdminStoragePath
        ) ?? panic("Could not borrow Admin reference from storage")
    }
    
    execute {
        // Start the drop
        self.adminRef.startDrop(
            startTime: startTime,
            endTime: endTime,
            gumPerFlunk: gumPerFlunk
        )
        
        log("GumDrop started!")
        log("Start time: ".concat(startTime.toString()))
        log("End time: ".concat(endTime.toString()))
        log("GUM per Flunk: ".concat(gumPerFlunk.toString()))
    }
}
