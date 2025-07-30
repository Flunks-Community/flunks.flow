import SimpleFlunksV2 from 0xbfffec679fff3a94

access(all) fun main(address: Address): [UInt64] {
    let account = getAccount(address)
    
    if let collectionRef = account.capabilities.borrow<&SimpleFlunksV2.Collection>(SimpleFlunksV2.CollectionPublicPath) {
        return collectionRef.getIDs()
    }
    
    return []
}
