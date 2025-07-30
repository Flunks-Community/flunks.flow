import MetadataViews from 0x1d7e57aa55817448
import SimpleFlunksV2 from 0xbfffec679fff3a94

access(all) fun main(ownerAddress: Address, nftID: UInt64): {String: AnyStruct} {
    let account = getAccount(ownerAddress)
    
    let collectionRef = account.capabilities.borrow<&SimpleFlunksV2.Collection>(SimpleFlunksV2.CollectionPublicPath)
        ?? panic("Could not borrow capability from public collection")
        
    let nft = collectionRef.borrowViewResolver(id: nftID)!
    
    let views: {String: AnyStruct} = {}
    
    // Check Display view
    if let display = nft.resolveView(Type<MetadataViews.Display>()) as! MetadataViews.Display? {
        views["Display"] = {
            "name": display.name,
            "description": display.description,
            "thumbnail": display.thumbnail.uri()
        }
    }
    
    // Check NFTCollectionData view
    if let collectionData = nft.resolveView(Type<MetadataViews.NFTCollectionData>()) as! MetadataViews.NFTCollectionData? {
        views["NFTCollectionData"] = {
            "storagePath": collectionData.storagePath.toString(),
            "publicPath": collectionData.publicPath.toString(),
            "publicCollection": collectionData.publicCollection.identifier,
            "publicLinkedType": collectionData.publicLinkedType.identifier
        }
    }
    
    // Check NFTCollectionDisplay view
    if let collectionDisplay = nft.resolveView(Type<MetadataViews.NFTCollectionDisplay>()) as! MetadataViews.NFTCollectionDisplay? {
        views["NFTCollectionDisplay"] = {
            "name": collectionDisplay.name,
            "description": collectionDisplay.description,
            "externalURL": collectionDisplay.externalURL.url,
            "squareImage": collectionDisplay.squareImage.file.uri(),
            "bannerImage": collectionDisplay.bannerImage.file.uri()
        }
    }
    
    // Check Royalties view
    if let royalties = nft.resolveView(Type<MetadataViews.Royalties>()) as! MetadataViews.Royalties? {
        views["Royalties"] = {
            "count": royalties.getRoyalties().length
        }
    }
    
    // Check ExternalURL view
    if let externalURL = nft.resolveView(Type<MetadataViews.ExternalURL>()) as! MetadataViews.ExternalURL? {
        views["ExternalURL"] = {
            "url": externalURL.url
        }
    }
    
    // Check Serial view
    if let serial = nft.resolveView(Type<MetadataViews.Serial>()) as! MetadataViews.Serial? {
        views["Serial"] = {
            "number": serial.number
        }
    }
    
    return views
}
