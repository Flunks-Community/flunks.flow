import NonFungibleToken from 0x1d7e57aa55817448
import MetadataViews from 0x1d7e57aa55817448
import Flunks from 0x807c3d470888cc48

// Get all NFT details from an account for display
access(all) fun main(address: Address): {String: AnyStruct} {
    let account = getAccount(address)
    let result: {String: AnyStruct} = {}
    
    result["address"] = address.toString()
    
    // Try to borrow the Flunks collection
    if let collection = account.capabilities.borrow<&Flunks.Collection>(Flunks.CollectionPublicPath) {
        let ids = collection.getIDs()
        result["flunksCount"] = ids.length
        result["flunksIDs"] = ids
        
        // Get details for first few NFTs
        var nftDetails: [{String: AnyStruct}] = []
        let limit = ids.length < 5 ? ids.length : 5
        var i = 0
        while i < limit {
            let nft = collection.borrowNFT(ids[i])
            let nftDetail: {String: AnyStruct} = {}
            nftDetail["id"] = ids[i]
            
            // Try to get Display view
            if let viewResolver = nft as? &{MetadataViews.Resolver} {
                if let display = viewResolver.resolveView(Type<MetadataViews.Display>()) as! MetadataViews.Display? {
                    nftDetail["name"] = display.name
                    nftDetail["description"] = display.description
                    nftDetail["thumbnail"] = display.thumbnail.uri()
                }
            }
            
            nftDetails.append(nftDetail)
            i = i + 1
        }
        result["sampleNFTs"] = nftDetails
    } else {
        result["flunksCount"] = 0
        result["error"] = "Could not borrow Flunks collection"
    }
    
    return result
}
