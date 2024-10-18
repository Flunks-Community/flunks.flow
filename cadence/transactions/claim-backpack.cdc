import NonFungibleToken from 0x1d7e57aa55817448
import Backpack from 0x807c3d470888cc48
import Patch from 0x807c3d470888cc48
import Flunks from 0x807c3d470888cc48
import BackpackMinter from 0x807c3d470888cc48

transaction(tokenID: UInt64, setID: UInt64) {

  let authSigner: auth(SaveValue, Capabilities, Storage, BorrowValue) &Account

  prepare(signer: auth(SaveValue, Capabilities, Storage, BorrowValue) &Account) {
    self.authSigner = signer

    // if the account doesn't already have Backpack
    if signer.storage.borrow<&Backpack.Collection>(from: Backpack.CollectionStoragePath) == nil {
        // create a new empty collection
        let collection <- Backpack.createEmptyCollection(nftType: Type<@Backpack.Collection>())
        // save it to the account
        signer.storage.save(<-collection, to: Backpack.CollectionStoragePath)
        // create a public capability for the collection
        let cap = signer.capabilities.storage.issue<&Backpack.Collection>(Backpack.CollectionStoragePath)
        signer.capabilities.publish(cap, at: Backpack.CollectionPublicPath)
    } else {
        // Unlink the existing collection (if any)
        signer.capabilities.unpublish(Backpack.CollectionPublicPath)

        // Re-link
        let cap = signer.capabilities.storage.issue<&Backpack.Collection>(Backpack.CollectionStoragePath)
        signer.capabilities.publish(cap, at: Backpack.CollectionPublicPath)
    }
  }

  execute {
    BackpackMinter.claimBackPack(tokenID: tokenID, signer: self.authSigner, setID: setID)
  }
}