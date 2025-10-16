import NFTCatalog from 0x49a7cda3a1eecc29

// Check if Flunks is in the NFT Catalog
access(all) fun main(): {String: AnyStruct} {
    let result: {String: AnyStruct} = {}
    
    // Try to get Flunks by collection identifier
    if let metadata = NFTCatalog.getCatalogEntry(collectionIdentifier: "Flunks") {
        result["found"] = true
        result["contractName"] = metadata.contractName
        result["contractAddress"] = metadata.contractAddress.toString()
        result["nftType"] = metadata.nftType.identifier
        result["collectionData"] = metadata.collectionData
        result["collectionDisplay"] = metadata.collectionDisplay
    } else {
        result["found"] = false
        result["message"] = "Flunks is not in the NFT Catalog"
    }
    
    // Also check what collections ARE in the catalog
    let allCollections = NFTCatalog.getCatalogKeys()
    result["totalCollectionsInCatalog"] = allCollections.length
    
    let samples: [String] = []
    let limit = allCollections.length < 10 ? allCollections.length : 10
    var i = 0
    while i < limit {
        samples.append(allCollections[i])
        i = i + 1
    }
    result["sampleCollections"] = samples
    
    return result
}
