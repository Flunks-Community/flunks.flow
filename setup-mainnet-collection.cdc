import NonFungibleToken from 0x1d7e57aa55817448
import SimpleFlunks from 0xbfffec679fff3a94

transaction {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Exit early if the account already stores a SimpleFlunks Collection
        if signer.storage.borrow<&SimpleFlunks.Collection>(from: SimpleFlunks.CollectionStoragePath) != nil {
            return
        }

        // Create a new empty collection
        let collection <- SimpleFlunks.createEmptyCollection(nftType: Type<@SimpleFlunks.NFT>())

        // save it to the account
        signer.storage.save(<-collection, to: SimpleFlunks.CollectionStoragePath)

        // create a public capability for the collection
        signer.capabilities.unpublish(SimpleFlunks.CollectionPublicPath)
        let collectionCap = signer.capabilities.storage.issue<&SimpleFlunks.Collection>(SimpleFlunks.CollectionStoragePath)
        signer.capabilities.publish(collectionCap, at: SimpleFlunks.CollectionPublicPath)
    }
}
