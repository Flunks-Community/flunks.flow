import SemesterZero from 0xb97ea2274b0ae5d2

/// Get Paradise Motel day/night image based on user's timezone
/// Returns image URL for current time in user's local timezone
/// Day: 6am-6pm, Night: 6pm-6am
access(all) fun main(userAddress: Address): {String: AnyStruct} {
    // Get user's profile
    let profileCap = getAccount(userAddress)
        .capabilities.get<&SemesterZero.UserProfile>(SemesterZero.UserProfilePublicPath)
    
    // Default to day image if no profile
    if !profileCap.check() {
        return {
            "hasProfile": false,
            "isDayTime": true,
            "localHour": 12,
            "image": "https://storage.googleapis.com/flunks_public/paradise-motel-day.png"
        }
    }
    
    let profile = profileCap.borrow()!
    
    // Get current blockchain timestamp (Unix timestamp in seconds)
    let currentTimestamp = getCurrentBlock().timestamp
    
    // Calculate UTC hour (timestamp is in seconds, so divide by 3600 to get hours)
    let utcHour = Int((currentTimestamp % 86400.0) / 3600.0)
    
    // Apply user's timezone offset
    var localHour = utcHour + profile.timezone
    
    // Handle day wrap-around
    if localHour < 0 {
        localHour = localHour + 24
    } else if localHour >= 24 {
        localHour = localHour - 24
    }
    
    // Determine if day or night (6am-6pm = day, 6pm-6am = night)
    let isDayTime = localHour >= 6 && localHour < 18
    
    let imageUrl = isDayTime 
        ? "https://storage.googleapis.com/flunks_public/paradise-motel-day.png"
        : "https://storage.googleapis.com/flunks_public/paradise-motel-night.png"
    
    return {
        "hasProfile": true,
        "username": profile.username,
        "timezone": profile.timezone,
        "utcHour": utcHour,
        "localHour": localHour,
        "isDayTime": isDayTime,
        "image": imageUrl
    }
}
