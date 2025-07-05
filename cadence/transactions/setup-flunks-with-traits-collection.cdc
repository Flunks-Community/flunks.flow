import SimpleFlunksWithTraits from 0xf8d6e0586b0a20c7
import NonFungibleToken from 0xf8d6e0586b0a20c7

transaction {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Check if collection already exists
        if signer.storage.borrow<&SimpleFlunksWithTraits.Collection>(
            from: SimpleFlunksWithTraits.CollectionStoragePath
        ) == nil {
            // Create a new empty collection
            let collection <- SimpleFlunksWithTraits.createEmptyCollection(nftType: Type<@SimpleFlunksWithTraits.Collection>())
            
            // Save it to storage
            signer.storage.save(<-collection, to: SimpleFlunksWithTraits.CollectionStoragePath)
        }
        
        // Create public capability if it doesn't exist
        if !signer.capabilities.get<&{NonFungibleToken.CollectionPublic}>(
            SimpleFlunksWithTraits.CollectionPublicPath
        ).check() {
            // Create and publish the capability
            let cap = signer.capabilities.storage.issue<&SimpleFlunksWithTraits.Collection>(
                SimpleFlunksWithTraits.CollectionStoragePath
            )
            signer.capabilities.publish(cap, at: SimpleFlunksWithTraits.CollectionPublicPath)
        }
        
        log("Collection setup complete")
    }
}
