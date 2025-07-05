import SimpleFlunksWithTraits from 0xf8d6e0586b0a20c7
import NonFungibleToken from 0xf8d6e0586b0a20c7

access(all) fun main(account: Address, tokenId: UInt64): {String: AnyStruct} {
    let collection = getAccount(account)
        .capabilities.borrow<&SimpleFlunksWithTraits.Collection>(SimpleFlunksWithTraits.CollectionPublicPath)
        ?? panic("Could not borrow collection")

    let nft = collection.borrowSimpleFlunksNFT(id: tokenId)
        ?? panic("Could not borrow NFT")
    
    var result: {String: AnyStruct} = {}
    result["id"] = nft.id
    result["name"] = nft.name
    result["description"] = nft.description
    result["image"] = nft.image
    result["externalURL"] = nft.externalURL
    result["animationURL"] = nft.animationURL
    result["edition"] = nft.edition
    result["maxEdition"] = nft.maxEdition
    
    var traits: [{String: AnyStruct}] = []
    for trait in nft.traits {
        var traitDict: {String: AnyStruct} = {}
        traitDict["name"] = trait.name
        traitDict["value"] = trait.value
        traitDict["displayType"] = trait.displayType
        traitDict["rarity"] = trait.rarity
        traits.append(traitDict)
    }
    result["traits"] = traits
    
    return result
}
