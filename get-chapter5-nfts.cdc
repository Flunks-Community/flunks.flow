import SemesterZero from 0xce9dd43888d99574
import MetadataViews from 0x1d7e57aa55817448

/// Get Chapter 5 NFTs for an account
access(all) fun main(address: Address): [UInt64] {
    let account = getAccount(address)
    
    let collectionRef = account.capabilities
        .get<&SemesterZero.Chapter5Collection>(SemesterZero.Chapter5CollectionPublicPath)
        .borrow()
    
    if collectionRef == nil {
        log("No Chapter 5 collection found")
        return []
    }
    
    let nftIDs = collectionRef!.getIDs()
    log("Found ".concat(nftIDs.length.toString()).concat(" Chapter 5 NFTs"))
    
    return nftIDs
}
