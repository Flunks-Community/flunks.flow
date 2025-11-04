import SemesterZero from "../contracts/SemesterZero.cdc"

/// Check if user is ready for autopush
/// Returns detailed status including GUM account, Flunks ownership, etc.
///
/// USAGE:
/// flow scripts execute ./cadence/scripts/check-autopush-eligibility.cdc \
///   --arg Address:0x1234567890123456

access(all) fun main(userAddress: Address): {String: AnyStruct} {
    let result: {String: AnyStruct} = {}
    let account = getAccount(userAddress)
    
    result["address"] = userAddress.toString()
    
    // 1. Check GUM Account
    let gumAccountCap = account.capabilities
        .get<&{SemesterZero.GumAccountPublic}>(SemesterZero.GumAccountPublicPath)
    
    if let gumAccount = gumAccountCap.borrow() {
        result["hasGumAccount"] = true
        result["currentBalance"] = gumAccount.getBalance()
        
        let info = gumAccount.getInfo()
        result["totalEarned"] = info.totalEarned
        result["totalSpent"] = info.totalSpent
    } else {
        result["hasGumAccount"] = false
        result["currentBalance"] = 0.0
        result["error"] = "User does not have GUM account - needs setup first"
    }
    
    // 2. Check User Profile
    let profileCap = account.capabilities
        .get<&SemesterZero.UserProfile>(SemesterZero.UserProfilePublicPath)
    
    if let profile = profileCap.borrow() {
        result["hasProfile"] = true
        result["username"] = profile.username
        result["timezone"] = profile.timezone
        result["isDaytime"] = profile.isDaytime()
        result["localHour"] = profile.getLocalHour()
    } else {
        result["hasProfile"] = false
    }
    
    // 3. Check if ready for autopush
    result["readyForAutopush"] = result["hasGumAccount"] as! Bool
    
    if result["readyForAutopush"] as! Bool {
        result["message"] = "✅ User is ready for autopush!"
    } else {
        result["message"] = "❌ User needs to set up GUM account first"
    }
    
    return result
}
