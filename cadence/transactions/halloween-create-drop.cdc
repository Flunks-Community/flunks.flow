import SemesterZero from "../contracts/SemesterZero.cdc"

/// Create a Halloween Special Drop
/// Users can claim this drop during the Halloween period
///
/// USAGE:
/// flow transactions send ./cadence/transactions/halloween-create-drop.cdc \
///   --arg String:"Halloween Treat 2025" \
///   --arg String:"Spooky GUM treats for all Flunks holders! 🎃👻" \
///   --arg UFix64:100.0 \
///   --arg UFix64:1729296000.0 \
///   --arg UFix64:1729900800.0 \
///   --arg Bool:true \
///   --arg Int:1 \
///   --arg UInt64:1000 \
///   --signer admin-account

transaction(
    name: String,                  // "Halloween Treat 2025"
    description: String,           // "Spooky GUM treats..."
    amount: UFix64,                // 100.0 GUM per claim
    startTime: UFix64,             // Unix timestamp (Oct 18, 2025)
    endTime: UFix64,               // Unix timestamp (Oct 25, 2025)
    requiredFlunks: Bool,          // true = must own Flunks
    minFlunksCount: Int,           // 1 = need at least 1 Flunks
    maxClaims: UInt64              // 1000 = max 1000 claims
) {
    
    prepare(admin: auth(BorrowValue) &Account) {
        // Borrow admin resource
        let adminRef = admin.storage.borrow<&SemesterZero.Admin>(
            from: SemesterZero.AdminStoragePath
        ) ?? panic("Could not borrow admin resource")
        
        // Create the Halloween drop
        adminRef.createSpecialDrop(
            name: name,
            description: description,
            amount: amount,
            startTime: startTime,
            endTime: endTime,
            requiredFlunks: requiredFlunks,
            minFlunksCount: minFlunksCount,
            maxClaims: maxClaims
        )
    }
    
    execute {
        log("Halloween Special Drop created successfully!")
        log("Name: ".concat(name))
        log("Amount: ".concat(amount.toString()).concat(" GUM"))
        log("Max Claims: ".concat(maxClaims.toString()))
    }
}
