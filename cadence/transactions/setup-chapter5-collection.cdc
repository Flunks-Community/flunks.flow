import SemesterZero from "../contracts/SemesterZero_Hackathon.cdc"
import NonFungibleToken from 0x1d7e57aa55817448

/// Setup Chapter 5 NFT collection
/// Run once per user before they can receive NFTs
transaction {
    
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Check if collection already exists
        if signer.storage.borrow<&SemesterZero.Chapter5Collection>(from: SemesterZero.Chapter5CollectionStoragePath) != nil {
            panic("Collection already exists")
        }
        
        // Create empty collection
        let collection <- SemesterZero.createEmptyChapter5Collection()
        
        // Save to storage
        signer.storage.save(<-collection, to: SemesterZero.Chapter5CollectionStoragePath)
        
        // Create public capability for depositing NFTs
        let cap = signer.capabilities.storage.issue<&{NonFungibleToken.Receiver}>(
            SemesterZero.Chapter5CollectionStoragePath
        )
        signer.capabilities.publish(cap, at: SemesterZero.Chapter5CollectionPublicPath)
        
        log("Chapter 5 collection created")
    }
}
