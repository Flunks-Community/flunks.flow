// Test script to verify Flunks NFTCollectionDisplay (with logo)
// This is what should show the Flunks logo on Flowty

import Flunks from 0x807c3d470888cc48
import MetadataViews from 0x1d7e57aa55817448

access(all) fun main(): AnyStruct? {
    let nftType = Type<@Flunks.NFT>()
    let viewType = Type<MetadataViews.NFTCollectionDisplay>()
    
    let result = Flunks.resolveContractView(
        resourceType: nftType,
        viewType: viewType
    )
    
    return result
}
