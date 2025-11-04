import SemesterZero from "../contracts/SemesterZero.cdc"

/// Check if user is eligible for Halloween claim
access(all) fun main(userAddress: Address): {String: AnyStruct} {
    let isEligible = SemesterZero.isEligibleForHalloween(userAddress)
    let hasClaimed = SemesterZero.hasClaimedHalloween(userAddress)
    let dropInfo = SemesterZero.getHalloweenDropInfo()
    
    return {
        "userAddress": userAddress,
        "isEligible": isEligible,
        "hasClaimed": hasClaimed,
        "canClaim": isEligible && !hasClaimed,
        "dropInfo": dropInfo
    }
}
