import SimpleFlunks from 0xf8d6e0586b0a20c7

transaction {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        log("🔍 Debug: Starting admin check...")
        
        // Check if admin resource exists
        let adminExists = signer.storage.check<@SimpleFlunks.Admin>(from: SimpleFlunks.AdminStoragePath)
        log("🔍 Debug: Admin resource exists: ".concat(adminExists ? "true" : "false"))
        
        if adminExists {
            log("✅ Admin resource found!")
        } else {
            log("❌ Admin resource NOT found!")
        }
        
        // Check total supply
        log("🔍 Debug: Current total supply: ".concat(SimpleFlunks.totalSupply.toString()))
        
        // Check collection exists
        let collectionExists = signer.storage.check<@SimpleFlunks.Collection>(from: SimpleFlunks.CollectionStoragePath)
        log("🔍 Debug: Collection exists: ".concat(collectionExists ? "true" : "false"))
    }
}
