import SimpleFlunks from 0xb97ea2274b0ae5d2
import NonFungibleToken from 0x631e88ae7f1d7c20

// Set up SimpleFlunks collection for testnet
transaction {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Check if collection already exists
        if signer.storage.borrow<&SimpleFlunks.Collection>(from: SimpleFlunks.CollectionStoragePath) == nil {
            // Create a new collection
            let collection <- SimpleFlunks.createEmptyCollection(nftType: Type<@SimpleFlunks.Collection>())
            
            // Store the collection in storage
            signer.storage.save(<-collection, to: SimpleFlunks.CollectionStoragePath)
            
            // Create a public capability for the collection
            let collectionCap = signer.capabilities.storage.issue<&{NonFungibleToken.CollectionPublic}>(SimpleFlunks.CollectionStoragePath)
            signer.capabilities.publish(collectionCap, at: SimpleFlunks.CollectionPublicPath)
            
            log("✅ SimpleFlunks collection set up successfully!")
        } else {
            log("✅ SimpleFlunks collection already exists!")
        }
    }
}
