import FlunksSemesterZero from 0xce9dd43888d99574
import NonFungibleToken from 0x1d7e57aa55817448

/// Setup FlunksSemesterZero collection on account
/// This creates the storage/public paths that Fixes.World needs to detect

transaction {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        
        // Check if collection already exists
        if signer.storage.borrow<&FlunksSemesterZero.Collection>(
            from: FlunksSemesterZero.CollectionStoragePath
        ) != nil {
            log("Collection already exists!")
            return
        }
        
        // Create new collection
        let collection <- FlunksSemesterZero.createEmptyCollection(nftType: Type<@FlunksSemesterZero.NFT>())
        
        // Save to storage
        signer.storage.save(<-collection, to: FlunksSemesterZero.CollectionStoragePath)
        
        // Create public capability
        let collectionCap = signer.capabilities.storage.issue<&{NonFungibleToken.CollectionPublic}>(
            FlunksSemesterZero.CollectionStoragePath
        )
        signer.capabilities.publish(collectionCap, at: FlunksSemesterZero.CollectionPublicPath)
        
        log("✅ FlunksSemesterZero collection created!")
    }
}
