import SemesterZero from 0xce9dd43888d99574

/// Get Paradise Motel day/night status for a user
access(all) fun main(userAddress: Address): {String: AnyStruct} {
    let result: {String: AnyStruct} = {}
    
    // Get user's profile to check timezone
    let account = getAccount(userAddress)
    let profileCap = account.capabilities
        .get<&SemesterZero.UserProfile>(SemesterZero.UserProfilePublicPath)
        .borrow()
    
    if profileCap == nil {
        result["hasProfile"] = false
        result["message"] = "User has no profile - cannot determine day/night"
        result["defaultImage"] = "night" // Default to night if no profile
        return result
    }
    
    result["hasProfile"] = true
    result["timezone"] = profileCap!.timezone
    result["username"] = profileCap!.username
    
    // Calculate if it's daytime based on timezone
    let currentTimestamp = getCurrentBlock().timestamp
    let currentHour = Int((currentTimestamp % 86400) / 3600) // Hour in UTC (0-23)
    let timezoneOffset = profileCap!.timezone
    let localHour = (currentHour + timezoneOffset + 24) % 24
    
    result["currentUTCHour"] = currentHour
    result["localHour"] = localHour
    
    // Day is 6 AM (6) to 6 PM (18)
    let isDaytime = localHour >= 6 && localHour < 18
    
    result["isDaytime"] = isDaytime
    result["timeOfDay"] = isDaytime ? "day" : "night"
    result["recommendedImage"] = isDaytime 
        ? "https://storage.googleapis.com/flunks_public/images/paradise-motel-day.png"
        : "https://storage.googleapis.com/flunks_public/images/paradise-motel-night.png"
    
    return result
}
