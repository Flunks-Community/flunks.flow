import SemesterZero from "../../contracts/SemesterZero.cdc"

/// Admin creates a GUM-gated NFT airdrop campaign
/// Users who meet requirements can claim Achievement NFTs
transaction(
    name: String,
    description: String,
    requiredGUM: UFix64,
    requiredFlunks: Bool,
    minFlunksCount: Int,
    totalSupply: UInt64,
    achievementType: String
) {
    
    prepare(admin: auth(Storage) &Account) {
        // Get admin resource
        let adminResource = admin.storage.borrow<&SemesterZero.Admin>(
            from: SemesterZero.AdminStoragePath
        ) ?? panic("❌ No admin resource found")
        
        // Create airdrop campaign
        adminResource.createAirdrop(
            name: name,
            description: description,
            requiredGUM: requiredGUM,
            requiredFlunks: requiredFlunks,
            minFlunksCount: minFlunksCount,
            totalSupply: totalSupply,
            achievementType: achievementType
        )
        
        log("✅ Airdrop created: ".concat(name))
        log("📋 Requirements:")
        log("   - GUM: ".concat(requiredGUM.toString()))
        log("   - Flunks required: ".concat(requiredFlunks ? "Yes (".concat(minFlunksCount.toString()).concat("+)") : "No"))
        log("   - Total supply: ".concat(totalSupply.toString()))
        log("   - Achievement type: ".concat(achievementType))
    }
    
    execute {
        log("🎁 Airdrop campaign is live!")
    }
}

/* EXAMPLES:

// "Early Adopter" - First 500 users with 100 GUM + 1 Flunks
flow transactions send ./cadence/transactions/semester-zero/admin-create-airdrop.cdc \
  --arg String:"Early Adopter Badge" \
  --arg String:"You were here at the beginning!" \
  --arg UFix64:100.0 \
  --arg Bool:true \
  --arg Int:1 \
  --arg UInt64:500 \
  --arg String:"early_supporter"

// "GUM Whale" - Top tier users with 10K GUM
flow transactions send ./cadence/transactions/semester-zero/admin-create-airdrop.cdc \
  --arg String:"GUM Whale Trophy" \
  --arg String:"Earned 10,000+ GUM - you're a legend!" \
  --arg UFix64:10000.0 \
  --arg Bool:false \
  --arg Int:0 \
  --arg UInt64:50 \
  --arg String:"gum_earner"

// "OG Flunks Holder" - Must own 5+ Flunks + 500 GUM
flow transactions send ./cadence/transactions/semester-zero/admin-create-airdrop.cdc \
  --arg String:"OG Flunks Holder" \
  --arg String:"True Flunks collector!" \
  --arg UFix64:500.0 \
  --arg Bool:true \
  --arg Int:5 \
  --arg UInt64:200 \
  --arg String:"og_flunks"

// "Hackathon Participant" - Everyone with any GUM
flow transactions send ./cadence/transactions/semester-zero/admin-create-airdrop.cdc \
  --arg String:"Forte Hackathon 2025" \
  --arg String:"Thank you for participating!" \
  --arg UFix64:1.0 \
  --arg Bool:false \
  --arg Int:0 \
  --arg UInt64:10000 \
  --arg String:"hackathon_winner"

*/
