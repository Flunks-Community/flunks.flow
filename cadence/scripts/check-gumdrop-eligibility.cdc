// Check user's claim data and eligibility

import GUMDrops from "../contracts/GUMDrops.cdc"

access(all) fun main(address: Address): {String: AnyStruct} {
    
    // Get the contract account
    let contractAccount = getAccount(0x807c3d470888cc48) // Replace with your deployed address
    
    // Borrow the claim tracker
    let tracker = contractAccount.capabilities
        .get<&GUMDrops.ClaimTracker>(GUMDrops.ClaimTrackerPublicPath)
        .borrow()
    
    if tracker == nil {
        return {
            "error": "Could not borrow ClaimTracker"
        }
    }
    
    let userData = tracker!.getUserData(address: address)
    
    let result: {String: AnyStruct} = {}
    
    if userData == nil {
        result["hasData"] = false
        result["canClaimCheckIn"] = tracker!.canClaimCheckIn(address: address)
        result["canClaimAM"] = tracker!.canClaimAMBonus(address: address)
        result["canClaimPM"] = tracker!.canClaimPMBonus(address: address)
        result["currentStreak"] = 0
    } else {
        result["hasData"] = true
        result["lastCheckInTime"] = userData!.lastCheckInTime
        result["currentStreak"] = userData!.currentStreak
        result["totalCheckIns"] = userData!.totalCheckIns
        result["lastAMClaim"] = userData!.lastAMClaim
        result["lastPMClaim"] = userData!.lastPMClaim
        result["totalGUMClaimed"] = userData!.totalGUMClaimed
        result["canClaimCheckIn"] = tracker!.canClaimCheckIn(address: address)
        result["canClaimAM"] = tracker!.canClaimAMBonus(address: address)
        result["canClaimPM"] = tracker!.canClaimPMBonus(address: address)
    }
    
    // Check time of day
    result["isAMHours"] = GUMDrops.isAMHours()
    result["isPMHours"] = GUMDrops.isPMHours()
    
    // Get Flunks count
    result["flunksCount"] = GUMDrops.getFlunksCount(address: address)
    
    return result
}
