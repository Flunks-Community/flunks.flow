// Simple script to check if Flunks contract is valid for Token List registration
import ViewResolver from 0x1d7e57aa55817448
import MetadataViews from 0x1d7e57aa55817448
import NonFungibleToken from 0x1d7e57aa55817448

access(all) fun main(address: Address, contractName: String): {String: AnyStruct} {
    let result: {String: AnyStruct} = {}
    result["address"] = address.toString()
    result["contractName"] = contractName
    
    // Try to borrow the contract as ViewResolver
    let account = getAccount(address)
    if let viewResolver = account.contracts.borrow<&{ViewResolver}>(name: contractName) {
        result["hasViewResolver"] = true
        
        // Check for NFTCollectionDisplay
        let contractViews = viewResolver.getContractViews(resourceType: nil)
        result["contractViews"] = contractViews.length
        result["viewTypes"] = contractViews.map(fun(t: Type): String { return t.identifier })
        
        let hasCollectionDisplay = contractViews.contains(Type<MetadataViews.NFTCollectionDisplay>())
        let hasCollectionData = contractViews.contains(Type<MetadataViews.NFTCollectionData>())
        
        result["hasNFTCollectionDisplay"] = hasCollectionDisplay
        result["hasNFTCollectionData"] = hasCollectionData
        result["isValid"] = hasCollectionDisplay && hasCollectionData
        
        // Get the actual display data
        if hasCollectionDisplay {
            if let display = viewResolver.resolveContractView(resourceType: nil, viewType: Type<MetadataViews.NFTCollectionDisplay>()) {
                let displayView = display as! MetadataViews.NFTCollectionDisplay
                result["name"] = displayView.name
                result["description"] = displayView.description
                result["externalURL"] = displayView.externalURL.url
                result["squareImage"] = displayView.squareImage.file.uri()
                result["bannerImage"] = displayView.bannerImage.file.uri()
            }
        }
        
        if hasCollectionData {
            if let data = viewResolver.resolveContractView(resourceType: nil, viewType: Type<MetadataViews.NFTCollectionData>()) {
                let dataView = data as! MetadataViews.NFTCollectionData
                result["storagePath"] = dataView.storagePath.toString()
                result["publicPath"] = dataView.publicPath.toString()
            }
        }
    } else {
        result["hasViewResolver"] = false
        result["isValid"] = false
        result["error"] = "Contract does not implement ViewResolver interface"
    }
    
    return result
}
