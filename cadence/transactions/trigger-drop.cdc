import SimpleDropHandler from 0x807c3d470888cc48

/// ANYONE can run this transaction to trigger the drop once the scheduled time is reached!
/// This is permissionless - first person to run it after Oct 31 12:01 AM will activate the drop
transaction {
    
    prepare(signer: &Account) {
        // Get the public handler capability from the admin account
        let handlerRef = getAccount(0x807c3d470888cc48)
            .capabilities.get<&{SimpleDropHandler.HandlerPublic}>(SimpleDropHandler.HandlerPublicPath)
            .borrow()
            ?? panic("Could not borrow handler reference")
        
        // Trigger the drop! (anyone can call this through the public interface)
        handlerRef.triggerDrop()
        
        log("🎃 GumDrop activated!")
    }
}
