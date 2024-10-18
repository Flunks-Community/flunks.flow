import Flunks from 0x807c3d470888cc48

access(all) fun main(address: Address): Int {
  let collection: &Flunks.Collection? = getAccount(address)
        .capabilities
        .borrow<&Flunks.Collection>(Flunks.CollectionPublicPath)
    
  let num = collection?.getIDs()?.length ?? 0

  return num
}