// Setup GUM account for user (one-time)

import GumDropsHybrid from "../../contracts/GumDropsHybrid.cdc"

transaction {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Check if already setup
        if signer.storage.borrow<&GumDropsHybrid.GumAccount>(
            from: GumDropsHybrid.GumAccountStoragePath
        ) != nil {
            log("GUM account already exists")
            return
        }
        
        // Create GUM account resource
        let gumAccount <- GumDropsHybrid.createGumAccount()
        signer.storage.save(<-gumAccount, to: GumDropsHybrid.GumAccountStoragePath)
        
        // Create public capability
        let cap = signer.capabilities.storage.issue<&GumDropsHybrid.GumAccount>(
            GumDropsHybrid.GumAccountStoragePath
        )
        signer.capabilities.publish(cap, at: GumDropsHybrid.GumAccountPublicPath)
        
        log("GUM account created successfully!")
    }
}
