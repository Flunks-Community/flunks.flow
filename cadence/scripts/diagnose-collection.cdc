// Check if an account has a Flunks collection properly set up
import Flunks from 0x807c3d470888cc48
import NonFungibleToken from 0x1d7e57aa55817448

access(all) fun main(address: Address): {String: AnyStruct} {
    let account = getAccount(address)
    let result: {String: AnyStruct} = {}
    
    // Check if collection exists at storage path
    let hasCollectionInStorage = account.storage.type(at: Flunks.CollectionStoragePath) != nil
    result["hasCollectionInStorage"] = hasCollectionInStorage
    result["collectionStoragePath"] = Flunks.CollectionStoragePath.toString()
    
    // Check if public capability exists
    let publicCap = account.capabilities.get<&Flunks.Collection>(Flunks.CollectionPublicPath)
    result["hasPublicCapability"] = publicCap != nil
    result["collectionPublicPath"] = Flunks.CollectionPublicPath.toString()
    
    // Try to borrow the collection
    if let collectionRef = account.capabilities.borrow<&Flunks.Collection>(Flunks.CollectionPublicPath) {
        result["canBorrowCollection"] = true
        result["nftIDs"] = collectionRef.getIDs()
        result["nftCount"] = collectionRef.getIDs().length
    } else {
        result["canBorrowCollection"] = false
        result["nftIDs"] = []
        result["nftCount"] = 0
    }
    
    // Check supported NFT types
    if let collectionRef = account.capabilities.borrow<&Flunks.Collection>(Flunks.CollectionPublicPath) {
        result["supportedNFTTypes"] = collectionRef.getSupportedNFTTypes()
    }
    
    return result
}