import SimpleDropHandler from 0x807c3d470888cc48

/// Admin transaction: Setup the drop handler with scheduled times
/// Run this once to prepare the handler
transaction(startTime: UFix64, endTime: UFix64, gumPerFlunk: UInt64) {
    
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Create the handler with scheduled times
        let handler <- SimpleDropHandler.createHandler(
            startTime: startTime,
            endTime: endTime,
            gumPerFlunk: gumPerFlunk
        )
        
        // Save to storage
        signer.storage.save(<-handler, to: SimpleDropHandler.HandlerStoragePath)
        
        // Create public capability so anyone can check status and trigger
        let cap = signer.capabilities.storage.issue<&{SimpleDropHandler.HandlerPublic}>(
            SimpleDropHandler.HandlerStoragePath
        )
        signer.capabilities.publish(cap, at: SimpleDropHandler.HandlerPublicPath)
        
        log("Drop handler created and scheduled")
    }
}
