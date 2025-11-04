import SemesterZero from 0xce9dd43888d99574
import MetadataViews from 0x1d7e57aa55817448

access(all) fun main(account: Address, nftID: UInt64): {String: AnyStruct} {
    let collection = getAccount(account)
        .capabilities.borrow<&SemesterZero.Chapter5Collection>(SemesterZero.Chapter5CollectionPublicPath)
        ?? panic("Could not borrow collection reference")
    
    let nft = collection.borrowChapter5NFT(id: nftID)
        ?? panic("Could not borrow NFT reference")
    
    // Get the Display view
    let display = nft.resolveView(Type<MetadataViews.Display>())! as! MetadataViews.Display
    
    return {
        "nftID": nft.id,
        "achievementType": nft.achievementType,
        "recipient": nft.recipient.toString(),
        "serialNumber": nft.serialNumber,
        "mintedAt": nft.mintedAt,
        "name": display.name,
        "description": display.description,
        "imageURL": display.thumbnail.uri(),
        "metadata": nft.metadata
    }
}
