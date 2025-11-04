// Test script to verify Flunks NFTCollectionDisplay is accessible
// This is what Flowty should be calling

import Flunks from 0x807c3d470888cc48
import MetadataViews from 0x1d7e57aa55817448

access(all) fun main(): AnyStruct? {
    // This is exactly what Flowty calls
    let nftType = Type<@Flunks.NFT>()
    let viewType = Type<MetadataViews.NFTCollectionData>()
    
    let result = Flunks.resolveContractView(
        resourceType: nftType,
        viewType: viewType
    )
    
    return result
}
