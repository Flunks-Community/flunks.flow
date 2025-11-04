import SemesterZero from "../../contracts/SemesterZero.cdc"

/// Check if a user is eligible to claim an airdrop
access(all) fun main(userAddress: Address, airdropID: UInt64): EligibilityResult {
    
    // Check eligibility
    let isEligible = SemesterZero.checkAirdropEligibility(
        claimer: userAddress,
        airdropID: airdropID
    )
    
    // Get airdrop info
    let airdrops = SemesterZero.getActiveAirdrops()
    var airdropInfo: SemesterZero.AirdropInfo? = nil
    
    for airdrop in airdrops {
        if airdrop.airdropID == airdropID {
            airdropInfo = airdrop
            break
        }
    }
    
    if airdropInfo == nil {
        return EligibilityResult(
            isEligible: false,
            reason: "Airdrop not found or inactive",
            airdropName: "",
            requiredGUM: 0.0,
            requiredFlunks: false,
            minFlunksCount: 0
        )
    }
    
    // Get user's GUM balance
    let account = getAccount(userAddress)
    let gumAccount = account.capabilities
        .get<&{SemesterZero.GumAccountPublic}>(SemesterZero.GumAccountPublicPath)
        .borrow()
    
    let userGumBalance = gumAccount?.getBalance() ?? 0.0
    
    // Determine why not eligible (if not)
    var reason = ""
    if !isEligible {
        if userGumBalance < airdropInfo!.requiredGUM {
            reason = "Insufficient GUM. Need ".concat(airdropInfo!.requiredGUM.toString())
                .concat(" but have ").concat(userGumBalance.toString())
        } else if airdropInfo!.requiredFlunks {
            reason = "Don't own enough Flunks. Need at least ".concat(airdropInfo!.minFlunksCount.toString())
        } else if !airdropInfo!.isActive {
            reason = "Airdrop supply depleted"
        } else {
            reason = "Already claimed"
        }
    } else {
        reason = "✅ Eligible to claim!"
    }
    
    return EligibilityResult(
        isEligible: isEligible,
        reason: reason,
        airdropName: airdropInfo!.name,
        requiredGUM: airdropInfo!.requiredGUM,
        requiredFlunks: airdropInfo!.requiredFlunks,
        minFlunksCount: airdropInfo!.minFlunksCount
    )
}

access(all) struct EligibilityResult {
    access(all) let isEligible: Bool
    access(all) let reason: String
    access(all) let airdropName: String
    access(all) let requiredGUM: UFix64
    access(all) let requiredFlunks: Bool
    access(all) let minFlunksCount: Int
    
    init(
        isEligible: Bool,
        reason: String,
        airdropName: String,
        requiredGUM: UFix64,
        requiredFlunks: Bool,
        minFlunksCount: Int
    ) {
        self.isEligible = isEligible
        self.reason = reason
        self.airdropName = airdropName
        self.requiredGUM = requiredGUM
        self.requiredFlunks = requiredFlunks
        self.minFlunksCount = minFlunksCount
    }
}

/* USAGE:

// Check if user can claim airdrop #1
flow scripts execute ./cadence/scripts/semester-zero/check-airdrop-eligibility.cdc \
  --arg Address:0x123... \
  --arg UInt64:1

// Returns:
{
  "isEligible": true,
  "reason": "✅ Eligible to claim!",
  "airdropName": "Early Adopter Badge",
  "requiredGUM": 100.0,
  "requiredFlunks": true,
  "minFlunksCount": 1
}

// OR if not eligible:
{
  "isEligible": false,
  "reason": "Insufficient GUM. Need 100.0 but have 50.0",
  "airdropName": "Early Adopter Badge",
  "requiredGUM": 100.0,
  "requiredFlunks": true,
  "minFlunksCount": 1
}

*/
