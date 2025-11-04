import ParadiseMotel from "../contracts/ParadiseMotel.cdc"

/// Get day/night status for multiple users at once
/// Perfect for batch rendering on your website
///
/// Example Response:
/// [
///   {
///     "address": "0x1234...",
///     "isDaytime": true,
///     "localHour": 10,
///     "timezone": -5,
///     "timeContext": "day"
///   },
///   {
///     "address": "0x5678...",
///     "isDaytime": false,
///     "localHour": 22,
///     "timezone": 8,
///     "timeContext": "night"
///   }
/// ]

access(all) fun main(addresses: [Address]): [{String: AnyStruct}] {
    return ParadiseMotel.batchGetTimeContext(addresses: addresses)
}
