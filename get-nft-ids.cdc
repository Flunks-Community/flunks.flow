import SimpleFlunks from 0xbfffec679fff3a94

access(all) fun main(account: Address): [UInt64] {
    let publicCollection = getAccount(account)
        .capabilities.borrow<&SimpleFlunks.Collection>(SimpleFlunks.CollectionPublicPath)
        ?? panic("Could not get public collection reference")
    
    return publicCollection.getIDs()
}
