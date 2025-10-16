import MetadataViews from 0x1d7e57aa55817448
import NFTCatalogAdmin from 0x49a7cda3a1eecc29
import NFTCatalog from 0x49a7cda3a1eecc29

// Direct update to Flunks NFT Catalog (requires NFTCatalogAdmin capability)
// Only works if you have admin access
transaction(
    newWebsiteURL: String,
    newDescription: String?
) {
    
    prepare(admin: auth(BorrowValue) &Account) {
        // This would only work if you have the NFTCatalogAdmin capability
        // Most likely you'll need to use the proposal method instead
        
        let adminProxy = admin.storage.borrow<&NFTCatalogAdmin.Admin>(
            from: /storage/NFTCatalogAdmin
        ) ?? panic("You don't have NFTCatalog admin access. Use the proposal method instead.")
        
        // Get current entry
        let currentEntry = NFTCatalog.getCatalogEntry(collectionIdentifier: "Flunks")
            ?? panic("Flunks not found in catalog")
        
        // Create updated collection display
        let updatedCollectionDisplay = MetadataViews.NFTCollectionDisplay(
            name: currentEntry.collectionDisplay.name,
            description: newDescription ?? currentEntry.collectionDisplay.description,
            externalURL: MetadataViews.ExternalURL(url: newWebsiteURL),
            squareImage: currentEntry.collectionDisplay.squareImage,
            bannerImage: currentEntry.collectionDisplay.bannerImage,
            socials: currentEntry.collectionDisplay.socials
        )
        
        // Create updated metadata
        let updatedMetadata = NFTCatalog.NFTCatalogMetadata(
            contractName: currentEntry.contractName,
            contractAddress: currentEntry.contractAddress,
            nftType: currentEntry.nftType,
            collectionData: currentEntry.collectionData,
            collectionDisplay: updatedCollectionDisplay
        )
        
        // Update the catalog
        adminProxy.updateCatalogEntry(
            collectionIdentifier: "Flunks",
            metadata: updatedMetadata
        )
        
        log("✅ Flunks catalog entry updated successfully!")
        log("New website: ".concat(newWebsiteURL))
    }
}
