import ParadiseMotel from "../contracts/ParadiseMotel.cdc"

/// Check if it's daytime for a specific timezone offset
/// Useful for testing or debugging
///
/// Example:
/// timezone: -5 (EST) -> checks if it's 6 AM - 6 PM in EST
/// timezone: 0 (UTC) -> checks if it's 6 AM - 6 PM in UTC
/// timezone: 9 (JST) -> checks if it's 6 AM - 6 PM in JST

access(all) fun main(timezone: Int): {String: AnyStruct} {
    let isDaytime = ParadiseMotel.isDaytimeForTimezone(timezone: timezone)
    let localHour = ParadiseMotel.getLocalHourForTimezone(timezone: timezone)
    
    return {
        "timezone": timezone,
        "isDaytime": isDaytime,
        "localHour": localHour,
        "timeContext": isDaytime ? "day" : "night",
        "dayStartHour": ParadiseMotel.DAY_START_HOUR,
        "nightStartHour": ParadiseMotel.NIGHT_START_HOUR
    }
}
