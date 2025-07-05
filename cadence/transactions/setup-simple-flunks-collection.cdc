import SimpleFlunks from 0xf8d6e0586b0a20c7
import NonFungibleToken from 0xf8d6e0586b0a20c7

transaction {
    prepare(acct: auth(Storage, Capabilities) &Account) {
        // Check if collection already exists
        if acct.storage.borrow<&SimpleFlunks.Collection>(from: SimpleFlunks.CollectionStoragePath) == nil {
            // Create new collection
            let collection <- SimpleFlunks.createEmptyCollection(nftType: Type<@SimpleFlunks.Collection>())
            
            // Save it to storage
            acct.storage.save(<-collection, to: SimpleFlunks.CollectionStoragePath)
            
            // Create public capability
            acct.capabilities.publish(
                acct.capabilities.storage.issue<&{NonFungibleToken.CollectionPublic}>(SimpleFlunks.CollectionStoragePath),
                at: SimpleFlunks.CollectionPublicPath
            )
            
            log("✅ SimpleFlunks collection set up successfully")
        } else {
            log("✅ SimpleFlunks collection already exists")
        }
    }
}
