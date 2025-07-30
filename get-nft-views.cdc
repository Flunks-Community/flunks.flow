import SimpleFlunks from 0xbfffec679fff3a94
import MetadataViews from 0x1d7e57aa55817448

access(all) fun main(account: Address, nftID: UInt64): [Type] {
    let publicCollection = getAccount(account)
        .capabilities.borrow<&SimpleFlunks.Collection>(SimpleFlunks.CollectionPublicPath)
        ?? panic("Could not get public collection reference")
    
    let nft = publicCollection.borrowViewResolver(id: nftID)
        ?? panic("Could not borrow NFT reference")
    
    return nft.getViews()
}
