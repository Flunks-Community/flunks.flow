// Check for Hybrid Custody linked accounts and their Flunks
import HybridCustody from 0xd8a7e05a7ac670c0
import Flunks from 0x807c3d470888cc48

access(all) fun main(address: Address): {String: AnyStruct} {
    let account = getAccount(address)
    let result: {String: AnyStruct} = {}
    
    result["parentAddress"] = address.toString()
    
    // Check if this account has a HybridCustody Manager
    if let manager = account.capabilities.borrow<&HybridCustody.Manager>(HybridCustody.ManagerPublicPath) {
        result["hasHybridCustodyManager"] = true
        
        let childAddresses = manager.getChildAddresses()
        result["childAccountCount"] = childAddresses.length
        
        var childAccounts: [{String: AnyStruct}] = []
        
        // Check each child account for Flunks
        for childAddress in childAddresses {
            let childAccount = getAccount(childAddress)
            let childInfo: {String: AnyStruct} = {}
            childInfo["address"] = childAddress.toString()
            
            // Try to get Flunks collection from child account
            if let flunksCollection = childAccount.capabilities.borrow<&Flunks.Collection>(Flunks.CollectionPublicPath) {
                let nftIDs = flunksCollection.getIDs()
                childInfo["hasFlunksCollection"] = true
                childInfo["flunksCount"] = nftIDs.length
                childInfo["flunksIDs"] = nftIDs
            } else {
                childInfo["hasFlunksCollection"] = false
                childInfo["flunksCount"] = 0
            }
            
            childAccounts.append(childInfo)
        }
        
        result["childAccounts"] = childAccounts
    } else {
        result["hasHybridCustodyManager"] = false
        result["childAccountCount"] = 0
    }
    
    // Also check the parent account itself
    if let flunksCollection = account.capabilities.borrow<&Flunks.Collection>(Flunks.CollectionPublicPath) {
        result["parentHasFlunks"] = true
        result["parentFlunksCount"] = flunksCollection.getIDs().length
        result["parentFlunksIDs"] = flunksCollection.getIDs()
    } else {
        result["parentHasFlunks"] = false
    }
    
    return result
}