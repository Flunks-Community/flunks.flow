import MetadataViews from 0x1d7e57aa55817448
import NFTCatalog from 0x49a7cda3a1eecc29

// Propose an update to the Flunks NFT Catalog entry
// This updates the website URL and other metadata
transaction(newWebsiteURL: String) {
    
    let proposalManager: auth(NFTCatalog.ProposalActionOwner) &NFTCatalog.NFTCatalogProposalManager
    
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Check if proposal manager exists, if not create it
        if signer.storage.borrow<&NFTCatalog.NFTCatalogProposalManager>(from: NFTCatalog.ProposalManagerStoragePath) == nil {
            let proposalManager <- NFTCatalog.createNFTCatalogProposalManager()
            signer.storage.save(<-proposalManager, to: NFTCatalog.ProposalManagerStoragePath)
            
            let proposalManagerCap = signer.capabilities.storage.issue<&NFTCatalog.NFTCatalogProposalManager>(
                NFTCatalog.ProposalManagerStoragePath
            )
            signer.capabilities.publish(proposalManagerCap, at: NFTCatalog.ProposalManagerPublicPath)
        }
        
        self.proposalManager = signer.storage.borrow<auth(NFTCatalog.ProposalActionOwner) &NFTCatalog.NFTCatalogProposalManager>(
            from: NFTCatalog.ProposalManagerStoragePath
        )!
        
        // Set the collection identifier for this proposal
        self.proposalManager.setCurrentProposalEntry(identifier: "Flunks")
    }
    
    execute {
        // Get the current Flunks catalog entry
        let currentEntry = NFTCatalog.getCatalogEntry(collectionIdentifier: "Flunks")
            ?? panic("Flunks not found in catalog")
        
        // Create updated collection display with new website
        let updatedCollectionDisplay = MetadataViews.NFTCollectionDisplay(
            name: currentEntry.collectionDisplay.name,
            description: currentEntry.collectionDisplay.description,
            externalURL: MetadataViews.ExternalURL(newWebsiteURL),
            squareImage: currentEntry.collectionDisplay.squareImage,
            bannerImage: currentEntry.collectionDisplay.bannerImage,
            socials: currentEntry.collectionDisplay.socials
        )
        
        // Create the updated metadata
        let updatedMetadata = NFTCatalog.NFTCatalogMetadata(
            contractName: currentEntry.contractName,
            contractAddress: currentEntry.contractAddress,
            nftType: currentEntry.nftType,
            collectionData: currentEntry.collectionData,
            collectionDisplay: updatedCollectionDisplay
        )
        
        // Propose the update
        let proposalID = NFTCatalog.proposeNFTMetadata(
            collectionIdentifier: "Flunks",
            metadata: updatedMetadata,
            message: "Update Flunks website URL to ".concat(newWebsiteURL),
            proposer: self.proposalManager.owner!.address
        )
        
        log("Proposal submitted with ID: ".concat(proposalID.toString()))
        log("The NFT Catalog admins will need to approve this proposal")
    }
}
