import SimpleFlunks from 0xf8d6e0586b0a20c7
import NonFungibleToken from 0xf8d6e0586b0a20c7
import MetadataViews from 0xf8d6e0586b0a20c7

access(all) fun main(account: Address): [UInt64] {
    let collection = getAccount(account)
        .capabilities.borrow<&{NonFungibleToken.CollectionPublic}>(/public/SimpleFlunksCollection)
        ?? panic("Could not get receiver reference to the NFT Collection")

    return collection.getIDs()
}
