# 🎁 NFT Airdrops on Flow - What You Need

## ✅ What You ALREADY Have

Your **SemesterZero** contract already includes:

1. **AchievementNFT Resource** - The NFT itself ✅
2. **AchievementCollection Resource** - Users' collection to hold NFTs ✅
3. **Airdrop System** - GUM-gated claiming logic ✅
4. **Setup Transaction** - Creates collection for users ✅

**You're 90% ready!**

---

## 🎯 What You Need to Do

### Option A: Use Existing Achievement NFTs (EASIEST)

**Use Case:** Airdrop achievement badges to users who reach GUM milestones

**Status:** ✅ Already built into SemesterZero!

```cadence
// Admin creates airdrop campaign
admin.createAirdrop(
    name: "Early Adopter Badge",
    description: "Reached 100 GUM!",
    requiredGUM: 100.0,
    requiredFlunks: true,
    minFlunksCount: 1,
    totalSupply: 500,
    achievementType: "early_supporter"
)

// User claims (mints Achievement NFT)
SemesterZero.claimAirdrop(
    airdropID: 1,
    claimer: userAddress,
    achievementCollection: &achievementCollection
)
```

**What users need:**
1. Run setup transaction (creates AchievementCollection) ✅
2. Have required GUM balance ✅
3. Have required Flunks (if gated) ✅

---

### Option B: Create New NFT Collection (If you want DIFFERENT NFTs)

**Use Case:** Airdrop special commemorative Flunks (not achievement badges)

**What's needed:**
1. Create new NFT contract (similar to existing Flunks.cdc)
2. Create collection resource
3. Create minting logic
4. Update airdrop system to mint from new contract

Let me show you both options:

---

## 🏆 Option A: Achievement NFT Airdrops (Recommended - Already Built!)

### What They Are:
- **Achievement Badges** that evolve based on GUM balance
- Already integrated with SemesterZero
- Automatic tier upgrades (Bronze → Silver → Gold → Platinum → Diamond)

### Types Available:
```cadence
// GUM Earner Achievement
achievementType: "gum_earner"
// Bronze: < 500 GUM
// Silver: 500-1000 GUM
// Gold: 1000-5000 GUM
// Platinum: 5000-10000 GUM
// Diamond: 10000+ GUM

// Tipper Achievement
achievementType: "tipper"
// Newcomer → Supporter → Generous → Very Generous → Legendary Tipper

// Spender Achievement  
achievementType: "spender"
// Window Shopper → Browser → Customer → Frequent Shopper → Big Spender

// Custom Achievement
achievementType: "early_supporter"
achievementType: "hackathon_winner"
achievementType: "og_flunks"
// etc. - you can make any achievement type!
```

### How to Airdrop:

#### 1. Admin Creates Airdrop Campaign

```cadence
transaction {
    prepare(admin: auth(Storage) &Account) {
        let adminResource = admin.storage.borrow<&SemesterZero.Admin>(
            from: SemesterZero.AdminStoragePath
        ) ?? panic("No admin resource")
        
        // Create "Early Adopter" airdrop
        adminResource.createAirdrop(
            name: "Early Adopter Badge",
            description: "You were here at the beginning!",
            requiredGUM: 100.0,           // Need 100 GUM to claim
            requiredFlunks: true,         // Must own Flunks
            minFlunksCount: 1,            // At least 1 Flunks
            totalSupply: 500,             // Only 500 available
            achievementType: "early_supporter"
        )
        
        log("✅ Airdrop created!")
    }
}
```

#### 2. Users Check Eligibility

```cadence
// Script to check if user is eligible
import SemesterZero from 0x...

access(all) fun main(userAddress: Address, airdropID: UInt64): Bool {
    return SemesterZero.checkAirdropEligibility(
        claimer: userAddress,
        airdropID: airdropID
    )
}

// Returns true if:
// - User has required GUM balance
// - User owns required Flunks (if gated)
// - User hasn't already claimed
// - Supply not depleted
```

#### 3. Users Claim (Mints Achievement NFT)

```cadence
transaction(airdropID: UInt64) {
    prepare(signer: auth(Storage) &Account) {
        // Get achievement collection
        let collection = signer.storage.borrow<&SemesterZero.AchievementCollection>(
            from: SemesterZero.AchievementCollectionStoragePath
        ) ?? panic("No achievement collection. Run setup first!")
        
        // Claim airdrop (mints Achievement NFT)
        let nftID = SemesterZero.claimAirdrop(
            airdropID: airdropID,
            claimer: signer.address,
            achievementCollection: collection
        )
        
        log("✅ Claimed Achievement NFT #".concat(nftID.toString()))
    }
}
```

### Asset Requirements:

You need images for achievement tiers:

```
achievements/
├── early_supporter_bronze.png
├── early_supporter_silver.png
├── early_supporter_gold.png
├── early_supporter_platinum.png
├── early_supporter_diamond.png
├── gum_earner_bronze.png
├── gum_earner_silver.png
└── ... (all tiers for all types)
```

**Image URL format:**
```
https://storage.googleapis.com/flunks_public/achievements/{type}_{tier}.png
```

Example:
```
https://storage.googleapis.com/flunks_public/achievements/early_supporter_bronze.png
https://storage.googleapis.com/flunks_public/achievements/gum_earner_gold.png
```

---

## 🆕 Option B: Create New NFT Collection (For Special Commemorative Flunks)

**Use Case:** You want to airdrop special Flunks variants (not just badges)

**Example:** "Semester Zero Commemorative Flunks" - special edition with unique artwork

### What You Need:

1. **New Contract** (e.g., `SemesterZeroNFT.cdc`)
2. **Metadata Templates** (like Flunks.cdc does)
3. **Collection Resource** (for users to hold them)
4. **Minting Logic** (admin mints and sends to users)

### Should You Do This?

**Pros:**
- ✅ Full control over NFT design
- ✅ Can make them more "collectible" than badges
- ✅ Can integrate with existing Flunks ecosystem

**Cons:**
- ❌ More complex (need new contract)
- ❌ Users need another collection setup
- ❌ More maintenance

**My Recommendation:** Start with Achievement NFT airdrops (Option A) for the hackathon. They're ready to go and still very cool!

---

## 🎯 Quick Start: Airdrop Achievement NFTs

### Step 1: User Setup (One-Time)

Users run the setup transaction (already created):

```bash
flow transactions send ./cadence/transactions/semester-zero/setup-complete.cdc \
  --arg String:"jeremy" \
  --arg Int:-8
```

This creates:
- ✅ Profile
- ✅ GUM Account
- ✅ **Achievement Collection** (ready for airdrops!)

### Step 2: Admin Creates Airdrop Campaigns

```cadence
// "Early Adopter" - First 500 users with 100 GUM
createAirdrop(
    name: "Early Adopter",
    requiredGUM: 100.0,
    totalSupply: 500,
    achievementType: "early_supporter"
)

// "GUM Whale" - Top tier users with 10K GUM
createAirdrop(
    name: "GUM Whale",
    requiredGUM: 10000.0,
    totalSupply: 50,
    achievementType: "gum_earner"
)

// "OG Flunks Holder" - Must own 5+ Flunks
createAirdrop(
    name: "OG Flunks Holder",
    requiredGUM: 500.0,
    requiredFlunks: true,
    minFlunksCount: 5,
    totalSupply: 200,
    achievementType: "og_flunks"
)
```

### Step 3: Users Claim

```typescript
// Frontend check eligibility
const eligible = await fcl.query({
  cadence: `
    import SemesterZero from 0x...
    access(all) fun main(user: Address, airdropID: UInt64): Bool {
      return SemesterZero.checkAirdropEligibility(claimer: user, airdropID: airdropID)
    }
  `,
  args: (arg, t) => [arg(userAddress, t.Address), arg("1", t.UInt64)]
});

if (eligible) {
  // Show "Claim Airdrop" button
  // User signs transaction to claim
}
```

### Step 4: Achievement NFT Auto-Evolves

```cadence
// User claims "Early Adopter" with 100 GUM
// → Mints Achievement NFT showing "Bronze" tier

// User earns more GUM (now has 1500 GUM)
// → Achievement NFT AUTOMATICALLY shows "Gold" tier

// User keeps earning (now has 10,000 GUM)
// → Achievement NFT AUTOMATICALLY shows "Diamond" tier
```

**No additional transactions needed - it just updates!**

---

## 📊 Comparison

### Achievement NFT Airdrops (Option A)
| Aspect | Status |
|--------|--------|
| Contract | ✅ Done (SemesterZero.cdc) |
| Collection | ✅ Done (AchievementCollection) |
| Setup Transaction | ✅ Done (setup-complete.cdc) |
| Claiming Logic | ✅ Done (claimAirdrop) |
| Eligibility Check | ✅ Done (checkAirdropEligibility) |
| Dynamic Metadata | ✅ Done (evolving tiers) |
| **Deployment** | ✅ Deploy 1 contract |
| **Assets Needed** | 🎨 Achievement tier images |

### New NFT Collection (Option B)
| Aspect | Status |
|--------|--------|
| Contract | ❌ Need to create |
| Collection | ❌ Need to create |
| Setup Transaction | ❌ Need to create |
| Claiming Logic | ❌ Need to create |
| Eligibility Check | ❌ Need to create |
| Metadata | ❌ Need to define |
| **Deployment** | ❌ Deploy 2 contracts |
| **Assets Needed** | 🎨 New NFT artwork |

---

## 💡 My Recommendation

### For Forte Hackathon:

**Go with Achievement NFT Airdrops (Option A)!**

**Why:**
- ✅ Already built and tested
- ✅ Unique feature (evolving based on GUM)
- ✅ Demonstrates hybrid on-chain/off-chain
- ✅ Fast to deploy
- ✅ Easy to demo
- ✅ Production-ready

**Just need to:**
1. Create achievement artwork (all tiers)
2. Deploy SemesterZero contract
3. Create airdrop campaigns
4. Build frontend claim UI

---

## 🎨 What You Need to Create

### Achievement Images

For each achievement type, create 5 tier images:

```
achievements/
├── early_supporter_bronze.png
├── early_supporter_silver.png
├── early_supporter_gold.png
├── early_supporter_platinum.png
├── early_supporter_diamond.png
├── gum_earner_bronze.png
├── gum_earner_silver.png
├── gum_earner_gold.png
├── gum_earner_platinum.png
├── gum_earner_diamond.png
├── og_flunks_bronze.png
├── og_flunks_silver.png
└── ... (etc.)
```

**Image specs:**
- Square format (1:1 ratio)
- Recommended: 512x512px or 1024x1024px
- PNG with transparency
- Clear visual progression (bronze → diamond should look increasingly premium)

---

## 🚀 Summary

**Question:** "do we need to start a collection on flow i guess if i'm going to airdrop users new NFT's?"

**Answer:** 

✅ **Achievement Collection is ALREADY BUILT in SemesterZero!**

Users just run the setup transaction and they're ready to receive airdropped Achievement NFTs!

**Next Steps:**
1. Create achievement artwork (5 tiers per type)
2. Deploy SemesterZero contract to testnet
3. Admin creates airdrop campaigns
4. Users claim and get evolving Achievement NFTs!

**No new collection needed - you're ready to go!** 🎉
