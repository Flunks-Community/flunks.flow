import SemesterZero from "../../contracts/SemesterZero.cdc"

/// User claims an airdrop (mints Achievement NFT)
transaction(airdropID: UInt64) {
    
    prepare(signer: auth(Storage) &Account) {
        // Get achievement collection
        let collection = signer.storage.borrow<&SemesterZero.AchievementCollection>(
            from: SemesterZero.AchievementCollectionStoragePath
        ) ?? panic("❌ No achievement collection found. Run setup-complete.cdc first!")
        
        // Claim airdrop (will mint Achievement NFT)
        let nftID = SemesterZero.claimAirdrop(
            airdropID: airdropID,
            claimer: signer.address,
            achievementCollection: collection
        )
        
        log("✅ Claimed airdrop!")
        log("🎉 Achievement NFT minted: #".concat(nftID.toString()))
    }
    
    execute {
        log("🏆 Check your collection to see your new Achievement NFT!")
    }
}

/* USAGE:

// Claim airdrop #1
flow transactions send ./cadence/transactions/semester-zero/claim-airdrop.cdc \
  --arg UInt64:1

// Will fail if:
// - User doesn't meet GUM requirement
// - User doesn't own required Flunks
// - User already claimed this airdrop
// - Airdrop supply is depleted
// - User doesn't have Achievement Collection (need to run setup first)

*/
