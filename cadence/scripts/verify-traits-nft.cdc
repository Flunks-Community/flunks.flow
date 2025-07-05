import SimpleFlunksWithTraits from 0xf8d6e0586b0a20c7
import NonFungibleToken from 0xf8d6e0586b0a20c7

access(all) fun main(account: Address, tokenId: UInt64): String {
    let collection = getAccount(account)
        .capabilities.borrow<&{NonFungibleToken.CollectionPublic}>(SimpleFlunksWithTraits.CollectionPublicPath)
        ?? panic("Could not borrow collection")

    let nft = collection.borrowNFT(tokenId)
        ?? panic("Could not borrow NFT")
    
    return "NFT ID: ".concat(nft.id.toString()).concat(" - Type: ").concat(nft.getType().identifier)
}
