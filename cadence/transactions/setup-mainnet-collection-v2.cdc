import NonFungibleToken from 0x1d7e57aa55817448
import SimpleFlunksV2 from 0xbfffec679fff3a94

transaction {
    prepare(signer: auth(BorrowValue, IssueStorageCapabilityController, PublishCapability, SaveValue, UnpublishCapability) &Account) {
        
        // Return early if the account already has a collection
        if signer.storage.borrow<&SimpleFlunksV2.Collection>(from: SimpleFlunksV2.CollectionStoragePath) != nil {
            return
        }

        // Create a new empty collection
        let collection <- SimpleFlunksV2.createEmptyCollection(nftType: Type<@SimpleFlunksV2.NFT>())

        // save it to the account
        signer.storage.save(<-collection, to: SimpleFlunksV2.CollectionStoragePath)

        // create a public capability for the collection
        let collectionCap = signer.capabilities.storage.issue<&SimpleFlunksV2.Collection>(SimpleFlunksV2.CollectionStoragePath)
        signer.capabilities.publish(collectionCap, at: SimpleFlunksV2.CollectionPublicPath)
    }
}
