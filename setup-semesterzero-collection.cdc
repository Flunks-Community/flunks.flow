import SemesterZero from 0xce9dd43888d99574
import NonFungibleToken from 0x1d7e57aa55817448
import MetadataViews from 0x1d7e57aa55817448

/// Set up SemesterZero Chapter5Collection for a user
/// This allows them to receive Chapter 5 NFT airdrops
transaction {
    prepare(signer: auth(BorrowValue, IssueStorageCapabilityController, PublishCapability, SaveValue, UnpublishCapability) &Account) {
        
        // Check if collection already exists
        if signer.storage.borrow<&SemesterZero.Chapter5Collection>(from: SemesterZero.Chapter5CollectionStoragePath) != nil {
            log("Collection already exists!")
            return
        }
        
        // Create new collection
        let collection <- SemesterZero.createEmptyChapter5Collection()
        
        // Save it to storage
        signer.storage.save(<-collection, to: SemesterZero.Chapter5CollectionStoragePath)
        
        // Unpublish any existing capability
        signer.capabilities.unpublish(SemesterZero.Chapter5CollectionPublicPath)
        
        // Create and publish new public capability
        let cap = signer.capabilities.storage.issue<&SemesterZero.Chapter5Collection>(
            SemesterZero.Chapter5CollectionStoragePath
        )
        signer.capabilities.publish(cap, at: SemesterZero.Chapter5CollectionPublicPath)
        
        log("✅ SemesterZero Chapter5Collection created successfully!")
    }
}
