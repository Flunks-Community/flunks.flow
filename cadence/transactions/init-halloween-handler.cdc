import HalloweenDropHandler from 0x807c3d470888cc48
import FlowTransactionScheduler from 0x0fd0e3a13a5e9142

/// Step 1: Initialize the Halloween Drop Handler
/// Run this transaction ONCE to set up the handler resource
/// 
/// This must be run by the account that owns the FlunksGumDrop Admin resource
/// (your mainnet account: 0x807c3d470888cc48)

transaction() {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Save a handler resource to storage if not already present
        if signer.storage.borrow<&AnyResource>(from: /storage/HalloweenDropHandler) == nil {
            let handler <- HalloweenDropHandler.createHandler()
            signer.storage.save(<-handler, to: /storage/HalloweenDropHandler)
            
            // Issue a non-entitled public capability for the handler
            let publicCap = signer.capabilities.storage
                .issue<&{FlowTransactionScheduler.TransactionHandler}>(/storage/HalloweenDropHandler)
            
            // Publish the capability
            signer.capabilities.publish(publicCap, at: /public/HalloweenDropHandler)
            
            log("✅ Halloween Drop Handler initialized")
        } else {
            log("⚠️  Handler already exists")
        }
    }
}
