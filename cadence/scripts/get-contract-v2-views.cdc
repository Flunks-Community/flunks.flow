import MetadataViews from 0x1d7e57aa55817448
import SimpleFlunksV2 from 0xbfffec679fff3a94

access(all) fun main(): {String: AnyStruct} {
    let views: {String: AnyStruct} = {}
    
    // Check contract-level NFTCollectionData
    if let collectionData = SimpleFlunksV2.resolveContractView(resourceType: nil, viewType: Type<MetadataViews.NFTCollectionData>()) as! MetadataViews.NFTCollectionData? {
        views["ContractNFTCollectionData"] = {
            "storagePath": collectionData.storagePath.toString(),
            "publicPath": collectionData.publicPath.toString(),
            "publicCollection": collectionData.publicCollection.identifier,
            "publicLinkedType": collectionData.publicLinkedType.identifier
        }
    }
    
    // Check contract-level NFTCollectionDisplay
    if let collectionDisplay = SimpleFlunksV2.resolveContractView(resourceType: nil, viewType: Type<MetadataViews.NFTCollectionDisplay>()) as! MetadataViews.NFTCollectionDisplay? {
        views["ContractNFTCollectionDisplay"] = {
            "name": collectionDisplay.name,
            "description": collectionDisplay.description,
            "externalURL": collectionDisplay.externalURL.url,
            "squareImage": collectionDisplay.squareImage.file.uri(),
            "bannerImage": collectionDisplay.bannerImage.file.uri()
        }
    }
    
    return views
}
