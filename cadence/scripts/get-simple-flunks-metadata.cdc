import SimpleFlunks from 0xf8d6e0586b0a20c7
import NonFungibleToken from 0xf8d6e0586b0a20c7
import MetadataViews from 0xf8d6e0586b0a20c7

access(all) fun main(account: Address, tokenId: UInt64): {String: String} {
    let collection = getAccount(account)
        .capabilities.borrow<&SimpleFlunks.Collection>(/public/SimpleFlunksCollection)
        ?? panic("Could not get receiver reference to the NFT Collection")

    let nft = collection.borrowNFT(tokenId) ?? panic("Could not borrow NFT")
    
    let simpleFlunksNFT = nft as! &SimpleFlunks.NFT
    
    var metadata: {String: String} = {}
    metadata["name"] = simpleFlunksNFT.name
    metadata["description"] = simpleFlunksNFT.description
    metadata["image"] = simpleFlunksNFT.image
    metadata["id"] = tokenId.toString()
    
    return metadata
}
