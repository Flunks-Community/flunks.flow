import ParadiseMotel from "../contracts/ParadiseMotel.cdc"
import SemesterZero from "../contracts/SemesterZero.cdc"

/// Get the current image URI for a Paradise Motel NFT based on owner's local time
/// This script integrates with your Supabase image timing logic
///
/// Example Response:
/// {
///   "imageURI": "https://flunks.io/paradise-motel/day/room-101.png",
///   "timeContext": "day",
///   "isDaytime": true,
///   "localHour": 14,
///   "timezone": -5,
///   "hasProfile": true
/// }

access(all) fun main(
    ownerAddress: Address,
    dayImageURI: String,
    nightImageURI: String
): {String: AnyStruct} {
    
    return ParadiseMotel.getCurrentImageForSupabase(
        ownerAddress: ownerAddress,
        dayImageURI: dayImageURI,
        nightImageURI: nightImageURI
    )
}
