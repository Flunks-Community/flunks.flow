import Flunks from 0x807c3d470888cc48
import NonFungibleToken from 0x1d7e57aa55817448

transaction {
  prepare(acct: auth(Storage, Capabilities) &Account) {
    if acct.storage.borrow<&Flunks.Collection>(from: Flunks.CollectionStoragePath) == nil {
      let collection <- Flunks.createEmptyCollection(nftType: Type<@Flunks.NFT>())
      acct.storage.save(<-collection, to: Flunks.CollectionStoragePath)

      let collectionCap = acct.capabilities.storage.issue<&Flunks.Collection>(Flunks.CollectionStoragePath)
      acct.capabilities.publish(collectionCap, at: Flunks.CollectionPublicPath)
      
      log("✅ Flunks collection initialized successfully")
    } else {
      log("ℹ️  Collection already exists")
    }
  }
}