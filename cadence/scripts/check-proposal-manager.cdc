import NFTCatalog from 0x49a7cda3a1eecc29

// Check if an account has an NFT Catalog proposal manager
access(all) fun main(address: Address): {String: AnyStruct} {
    let account = getAccount(address)
    let result: {String: AnyStruct} = {}
    
    result["address"] = address.toString()
    
    // Check if proposal manager exists
    if let manager = account.capabilities.borrow<&NFTCatalog.NFTCatalogProposalManager>(
        NFTCatalog.ProposalManagerPublicPath
    ) {
        result["hasProposalManager"] = true
        result["currentProposalEntry"] = manager.getCurrentProposalEntry()
    } else {
        result["hasProposalManager"] = false
        result["message"] = "No proposal manager found. The transaction will create one."
    }
    
    return result
}
