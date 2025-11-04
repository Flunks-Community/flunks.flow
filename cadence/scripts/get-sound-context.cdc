import ParadiseMotel from 0x807c3d470888cc48
import SemesterZero from 0x807c3d470888cc48

/// Check Day/Night Status for Ambient Sounds
/// Returns whether it's currently daytime or nighttime based on user's timezone
/// Use this to trigger ambient sounds (crickets at night, birds during day, etc.)
///
/// Returns:
/// {
///   "isDaytime": false,          // true = day (6 AM - 6 PM), false = night (6 PM - 6 AM)
///   "timeContext": "night",      // "day" or "night"
///   "localHour": 21,             // User's local hour (0-23)
///   "timezone": -5,              // User's timezone offset from UTC
///   "utcHour": 2,                // Current UTC hour
///   "hasProfile": true,          // Whether user has set up their profile
///   "soundContext": "night",     // Suggested sound theme
///   "intensity": "deep-night"    // Time-based intensity level
/// }

access(all) fun main(userAddress: Address): {String: AnyStruct} {
    let account = getAccount(userAddress)
    
    // Try to get user's profile
    let profileRef = account.capabilities
        .get<&SemesterZero.UserProfile>(SemesterZero.UserProfilePublicPath)
        .borrow()
    
    // Get current UTC time
    let timestamp = getCurrentBlock().timestamp
    let utcHour = Int((timestamp / 3600.0) % 24.0)
    
    // If no profile, use UTC time as default
    if profileRef == nil {
        let defaultIsDaytime = utcHour >= 6 && utcHour < 18
        return {
            "isDaytime": defaultIsDaytime,
            "timeContext": defaultIsDaytime ? "day" : "night",
            "localHour": utcHour,
            "timezone": 0,
            "utcHour": utcHour,
            "hasProfile": false,
            "soundContext": defaultIsDaytime ? "day" : "night",
            "intensity": getSoundIntensity(utcHour, defaultIsDaytime)
        }
    }
    
    // Calculate user's local time
    let profile = profileRef!
    let timezone = profile.timezone
    var localHour = utcHour + timezone
    
    // Wrap around for valid hours (0-23)
    if localHour < 0 {
        localHour = localHour + 24
    } else if localHour >= 24 {
        localHour = localHour - 24
    }
    
    // Check if daytime (6 AM - 6 PM)
    let isDaytime = ParadiseMotel.isDaytimeForTimezone(timezone: timezone)
    
    return {
        "isDaytime": isDaytime,
        "timeContext": isDaytime ? "day" : "night",
        "localHour": localHour,
        "timezone": timezone,
        "utcHour": utcHour,
        "hasProfile": true,
        "username": profile.username,
        "soundContext": getSoundContext(localHour, isDaytime),
        "intensity": getSoundIntensity(localHour, isDaytime)
    }
}

/// Get sound context based on time of day
/// Returns: "dawn", "day", "dusk", "night", "deep-night"
access(all) fun getSoundContext(_ hour: Int, _ isDaytime: Bool): String {
    if isDaytime {
        // Day time (6 AM - 6 PM)
        if hour >= 6 && hour < 8 {
            return "dawn"  // Early morning birds, gentle ambience
        } else if hour >= 8 && hour < 17 {
            return "day"   // Full daytime sounds
        } else {
            return "dusk"  // Evening transition
        }
    } else {
        // Night time (6 PM - 6 AM)
        if hour >= 18 && hour < 22 {
            return "evening"      // Early night, crickets starting
        } else if hour >= 22 || hour < 2 {
            return "night"        // Deep night, owls, distant sounds
        } else if hour >= 2 && hour < 5 {
            return "deep-night"   // Darkest hours, minimal sounds
        } else {
            return "pre-dawn"     // Very early morning
        }
    }
}

/// Get sound intensity level
/// Returns intensity suggestion for volume/layering
access(all) fun getSoundIntensity(_ hour: Int, _ isDaytime: Bool): String {
    if isDaytime {
        if hour >= 6 && hour < 8 {
            return "low"      // Gentle dawn
        } else if hour >= 8 && hour < 12 {
            return "medium"   // Morning activity
        } else if hour >= 12 && hour < 17 {
            return "high"     // Peak day
        } else {
            return "medium"   // Evening wind down
        }
    } else {
        if hour >= 18 && hour < 20 {
            return "medium"      // Dusk ambience
        } else if hour >= 20 || hour < 4 {
            return "high"        // Peak night sounds
        } else {
            return "low"         // Pre-dawn quiet
        }
    }
}
