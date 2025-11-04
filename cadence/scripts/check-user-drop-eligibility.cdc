import SemesterZero from "../contracts/SemesterZero.cdc"
import NonFungibleToken from "../contracts/NonFungibleToken.cdc"

/// Check if a user is eligible to claim a specific drop
/// Shows detailed information about why they can or cannot claim
///
/// USAGE:
/// flow scripts execute ./cadence/scripts/check-user-drop-eligibility.cdc \
///   --arg Address:0x1234... \
///   --arg UInt64:1

access(all) fun main(userAddress: Address, dropID: UInt64): {String: AnyStruct} {
    let account = getAccount(userAddress)
    let result: {String: AnyStruct} = {}
    
    // Get drop info
    let dropInfo = SemesterZero.getDropInfo(dropID: dropID)
    if dropInfo == nil {
        result["error"] = "Drop not found"
        return result
    }
    
    let drop = dropInfo!
    result["dropName"] = drop.name
    result["dropAmount"] = drop.amount
    result["isDropActive"] = drop.isActive
    
    // Check if user has GUM account
    let gumAccount = account.capabilities
        .get<&{SemesterZero.GumAccountPublic}>(SemesterZero.GumAccountPublicPath)
        .borrow()
    
    if gumAccount == nil {
        result["eligible"] = false
        result["reason"] = "No GUM account found"
        return result
    }
    
    result["currentGumBalance"] = gumAccount!.getBalance()
    
    // Check Flunks requirement
    if drop.requiredFlunks {
        let flunksCollection = account.capabilities
            .get<&{NonFungibleToken.CollectionPublic}>(/public/FlunksCollection)
            .borrow()
        
        let flunksCount = flunksCollection?.getIDs()?.length ?? 0
        result["flunksOwned"] = flunksCount
        result["flunksRequired"] = drop.minFlunksCount
        
        if flunksCount < drop.minFlunksCount {
            result["eligible"] = false
            result["reason"] = "Insufficient Flunks owned"
            return result
        }
    }
    
    // If we get here, user is eligible!
    result["eligible"] = true
    result["reason"] = "Ready to claim!"
    
    return result
}
