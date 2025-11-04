import FlunksGumDrop from 0x807c3d470888cc48

/// Admin Transaction: Start the Halloween GumDrop
/// 
/// This activates the GumDrop on mainnet so users can claim!
/// Arguments:
/// - startTime: Unix timestamp when drop begins
/// - endTime: Unix timestamp when drop ends  
/// - gumPerFlunk: Amount of GUM each user gets (100 for Halloween)

transaction(startTime: UFix64, endTime: UFix64, gumPerFlunk: UInt64) {
    
    let adminRef: &FlunksGumDrop.Admin
    
    prepare(signer: auth(Storage) &Account) {
        // Borrow admin capability
        self.adminRef = signer.storage.borrow<&FlunksGumDrop.Admin>(
            from: FlunksGumDrop.AdminStoragePath
        ) ?? panic("Could not borrow Admin reference from storage")
    }
    
    execute {
        // Start the drop
        self.adminRef.startDrop(
            startTime: startTime,
            endTime: endTime,
            gumPerFlunk: gumPerFlunk
        )
        
        log("✅ Halloween GumDrop activated!")
        log("Start time: ".concat(startTime.toString()))
        log("End time: ".concat(endTime.toString()))
        log("GUM per claim: ".concat(gumPerFlunk.toString()))
    }
}
