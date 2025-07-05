import Flunks from 0xf8d6e0586b0a20c7
import NonFungibleToken from 0xf8d6e0586b0a20c7

transaction {
  prepare(acct: auth(Storage, Capabilities) &Account) {
    if acct.borrow<&Flunks.Collection>(from: Flunks.CollectionStoragePath) == nil {
      let collection <- Flunks.createEmptyCollection(nftType: Type<@Flunks.Collection>())
      acct.storage.save(<-collection, to: Flunks.CollectionStoragePath)

      acct.capabilities.storage.issue<&{NonFungibleToken.CollectionPublic, Flunks.FlunksCollectionPublic}>(
        Flunks.CollectionPublicPath,
        target: Flunks.CollectionStoragePath
      )
    }
  }
}
