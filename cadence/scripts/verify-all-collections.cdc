import NonFungibleToken from 0x1d7e57aa55817448
import MetadataViews from 0x1d7e57aa55817448
import SimpleFlunks from 0xbfffec679fff3a94
import SimpleFlunksWithTraits from 0xbfffec679fff3a94
import SimpleFlunksV2 from 0xbfffec679fff3a94

access(all) fun main(address: Address): {String: AnyStruct} {
    let account = getAccount(address)
    let result: {String: AnyStruct} = {}
    
    // Check SimpleFlunks collection
    if let collection1 = account.capabilities.borrow<&SimpleFlunks.Collection>(SimpleFlunks.CollectionPublicPath) {
        result["SimpleFlunks"] = {
            "exists": true,
            "nftCount": collection1.getIDs().length,
            "nftIDs": collection1.getIDs()
        }
    } else {
        result["SimpleFlunks"] = {"exists": false}
    }
    
    // Check SimpleFlunksWithTraits collection
    if let collection2 = account.capabilities.borrow<&SimpleFlunksWithTraits.Collection>(SimpleFlunksWithTraits.CollectionPublicPath) {
        result["SimpleFlunksWithTraits"] = {
            "exists": true,
            "nftCount": collection2.getIDs().length,
            "nftIDs": collection2.getIDs()
        }
    } else {
        result["SimpleFlunksWithTraits"] = {"exists": false}
    }
    
    // Check SimpleFlunksV2 collection
    if let collection3 = account.capabilities.borrow<&SimpleFlunksV2.Collection>(SimpleFlunksV2.CollectionPublicPath) {
        result["SimpleFlunksV2"] = {
            "exists": true,
            "nftCount": collection3.getIDs().length,
            "nftIDs": collection3.getIDs()
        }
        
        // Get detailed info for first NFT if exists
        let ids = collection3.getIDs()
        if ids.length > 0 {
            if let nft = collection3.borrowViewResolver(id: ids[0]) {
                let display = nft.resolveView(Type<MetadataViews.Display>()) as! MetadataViews.Display?
                let collectionData = nft.resolveView(Type<MetadataViews.NFTCollectionData>()) as! MetadataViews.NFTCollectionData?
                
                result["SimpleFlunksV2_NFT_0"] = {
                    "id": ids[0],
                    "name": display?.name ?? "Unknown",
                    "description": display?.description ?? "Unknown",
                    "image": display?.thumbnail?.uri() ?? "Unknown",
                    "hasCollectionData": collectionData != nil,
                    "publicLinkedType": collectionData?.publicLinkedType?.identifier ?? "Missing"
                }
            }
        }
    } else {
        result["SimpleFlunksV2"] = {"exists": false}
    }
    
    return result
}
