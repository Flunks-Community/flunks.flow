# 🎓 Semester Zero - Complete Flunks Ecosystem

## 🌟 Overview

**SemesterZero** is a unified smart contract that brings together all the innovative features for the Forte Hackathon 2025:

### Core Features:
1. ✅ **GUM System** - Hybrid on-chain/off-chain points (NOT a token)
2. ✅ **Dynamic Time-Based NFTs** - Flunks change appearance day/night based on YOUR timezone
3. ✅ **Evolving Achievement NFTs** - NFTs that level up as you earn GUM
4. ✅ **Special Drops** - Time-limited event drops with NFT gating
5. ✅ **GUM-Gated Airdrops** - Unlock exclusive Achievement NFTs by reaching GUM milestones
6. ✅ **User Profiles** - On-chain profiles with timezone for dynamic NFTs
7. ✅ **Social Features** - Transfer GUM with messages, leaderboards

---

## 📁 What We Built

### Contracts (3 new files):
- `SemesterZero.cdc` - Main unified contract (1,000+ lines)
- `FlunksDynamicViews.cdc` - Wrapper for dynamic Flunks metadata
- `GumDropsHybrid.cdc` - Original standalone version (still exists)

### How It Works:
```
┌─────────────────────────────────────────────────────────┐
│                    Semester Zero                        │
│                                                         │
│  ┌────────────┐  ┌──────────────┐  ┌────────────────┐ │
│  │ GUM System │  │  User Profile│  │  Achievement   │ │
│  │            │  │  (Timezone)  │  │  NFTs          │ │
│  │ - Balance  │  │              │  │                │ │
│  │ - Transfer │  │  - isDaytime()│  │  - Evolving   │ │
│  │ - Spend    │  │  - localHour │  │  - Dynamic     │ │
│  └────────────┘  └──────────────┘  └────────────────┘ │
│                                                         │
│  ┌────────────┐  ┌──────────────┐  ┌────────────────┐ │
│  │ Special    │  │  Airdrops    │  │  Admin         │ │
│  │ Drops      │  │              │  │  Controls      │ │
│  │            │  │  - GUM-gated │  │                │ │
│  │ - Timed    │  │  - NFT-gated │  │  - Sync        │ │
│  │ - NFT-gated│  │  - Limited   │  │  - Create      │ │
│  └────────────┘  └──────────────┘  └────────────────┘ │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
            ┌──────────────────────────┐
            │  FlunksDynamicViews      │
            │                          │
            │  - Day/Night Images      │
            │  - Owner Stats           │
            │  - Dynamic Metadata      │
            └──────────────────────────┘
                          │
                          ▼
                  ┌──────────────┐
                  │  Flunks.cdc  │
                  │  (Existing)  │
                  └──────────────┘
```

---

## 🎯 Key Innovations

### 1. ⏰ Time-Based Dynamic NFTs

Your Flunks NFTs will show **different artwork** based on YOUR local time!

**How It Works:**
1. User creates profile with timezone: `createUserProfile(username: "jeremy", timezone: -8)` (PST)
2. Profile calculates if it's daytime: `isDaytime()` returns true if 6 AM - 6 PM in YOUR timezone
3. Flunks NFT checks profile and shows day or night image
4. Works in real-time on marketplaces!

**Example:**
```cadence
// User in California (PST, UTC-8)
let profile = account.capabilities.get<&UserProfile>(...).borrow()!
profile.getLocalHour() // Returns 14 (2 PM PST)
profile.isDaytime()    // Returns true

// Flunks NFT automatically shows daytime artwork!
```

**Metadata Structure:**
```json
{
  "name": "Flunks #42",
  "uri": "https://storage.googleapis.com/flunks_public/flunks/default.png",
  "dayImageUri": "https://storage.googleapis.com/flunks_public/flunks/42_day.png",
  "nightImageUri": "https://storage.googleapis.com/flunks_public/flunks/42_night.png"
}
```

### 2. 🏆 Evolving Achievement NFTs

Achievement NFTs that **change appearance** based on your GUM balance!

**Achievement Types:**

#### GUM Earner Achievement
- **Bronze**: < 500 GUM earned
- **Silver**: 500-1000 GUM earned
- **Gold**: 1000-5000 GUM earned
- **Platinum**: 5000-10,000 GUM earned
- **Diamond**: 10,000+ GUM earned

#### Tipper Achievement
- **Newcomer**: < 25 GUM transferred
- **Supporter**: 25-100 GUM transferred
- **Generous**: 100-500 GUM transferred
- **Very Generous**: 500-1000 GUM transferred
- **Legendary Tipper**: 1000+ GUM transferred

#### Spender Achievement
- **Window Shopper**: < 100 GUM spent
- **Browser**: 100-500 GUM spent
- **Customer**: 500-2000 GUM spent
- **Frequent Shopper**: 2000-5000 GUM spent
- **Big Spender**: 5000+ GUM spent

**Dynamic Metadata:**
```cadence
let achievement: &AchievementNFT = ...
achievement.getCurrentTier() // Returns "Gold" if 2500 GUM earned

// NFT image URL changes automatically!
// "https://.../gum_earner_gold.png"
```

### 3. 🎁 GUM-Gated Airdrops

Unlock exclusive Achievement NFTs by reaching GUM milestones!

**Example Airdrops:**
```cadence
// "Early Adopter" - Requires 100 GUM + 1 Flunks
createAirdrop(
    name: "Early Adopter Badge",
    requiredGUM: 100.0,
    requiredFlunks: true,
    minFlunksCount: 1,
    totalSupply: 500,
    achievementType: "early_supporter"
)

// "GUM Whale" - Requires 10,000 GUM
createAirdrop(
    name: "GUM Whale Trophy",
    requiredGUM: 10000.0,
    requiredFlunks: true,
    minFlunksCount: 5,
    totalSupply: 50,
    achievementType: "gum_earner"
)
```

### 4. 🎉 Special Drops (Time-Limited Events)

Create time-limited GUM drops with NFT gating:

```cadence
// "Weekend Bonus" - 50 GUM, must own 1+ Flunks
createSpecialDrop(
    name: "Weekend Bonus",
    description: "Extra GUM for the weekend!",
    amount: 50.0,
    startTime: 1729296000.0,  // Friday 5 PM
    endTime: 1729468800.0,    // Sunday 11:59 PM
    requiredFlunks: true,
    minFlunksCount: 1,
    maxClaims: 1000
)
```

---

## 🚀 User Flow

### Initial Setup (One-Time)

```cadence
// 1. Create profile with timezone
transaction {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        let profile <- SemesterZero.createUserProfile(
            username: "jeremy",
            timezone: -8  // PST
        )
        signer.storage.save(<-profile, to: SemesterZero.UserProfileStoragePath)
        
        let profileCap = signer.capabilities.storage.issue<&SemesterZero.UserProfile>(
            SemesterZero.UserProfileStoragePath
        )
        signer.capabilities.publish(profileCap, at: SemesterZero.UserProfilePublicPath)
    }
}

// 2. Create GUM account
transaction {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        let gumAccount <- SemesterZero.createGumAccount(initialBalance: 0.0)
        signer.storage.save(<-gumAccount, to: SemesterZero.GumAccountStoragePath)
        
        let gumCap = signer.capabilities.storage.issue<&SemesterZero.GumAccount>(
            SemesterZero.GumAccountStoragePath
        )
        signer.capabilities.publish(gumCap, at: SemesterZero.GumAccountPublicPath)
    }
}

// 3. Create achievement collection
transaction {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        let collection <- SemesterZero.createEmptyAchievementCollection()
        signer.storage.save(<-collection, to: SemesterZero.AchievementCollectionStoragePath)
        
        let collectionCap = signer.capabilities.storage.issue<&SemesterZero.AchievementCollection>(
            SemesterZero.AchievementCollectionStoragePath
        )
        signer.capabilities.publish(collectionCap, at: SemesterZero.AchievementCollectionPublicPath)
    }
}
```

### Daily Usage

```cadence
// User earns GUM on website (Supabase)
// → Admin syncs to blockchain
admin.syncUserBalance(userAddress: 0x123..., newBalance: 150.0)

// User views their Flunks
// → Shows daytime or nighttime artwork automatically based on their timezone!

// User transfers GUM to friend
gumAccount.transfer(amount: 10.0, to: 0x456..., message: "Thanks!")

// User claims special drop
SemesterZero.claimSpecialDrop(dropID: 1, gumAccount: &gumAccount)

// User checks airdrop eligibility
SemesterZero.checkAirdropEligibility(claimer: 0x123..., airdropID: 1) // true

// User claims airdrop
SemesterZero.claimAirdrop(
    airdropID: 1,
    claimer: 0x123...,
    achievementCollection: &achievementCollection
)
// → Mints Achievement NFT!

// Achievement NFT automatically shows current tier based on GUM balance
achievementNFT.getCurrentTier() // "Silver" if 750 GUM earned
```

---

## 📊 Admin Functions

### Sync GUM from Supabase
```cadence
admin.syncUserBalance(userAddress: 0x123..., newBalance: 250.0)
// Emits: GumSynced(owner: 0x123..., oldBalance: 150.0, newBalance: 250.0)
```

### Create Special Drop
```cadence
admin.createSpecialDrop(
    name: "Holiday Bonus",
    description: "Special holiday GUM drop!",
    amount: 100.0,
    startTime: getCurrentBlock().timestamp,
    endTime: getCurrentBlock().timestamp + 86400.0, // 24 hours
    requiredFlunks: true,
    minFlunksCount: 1,
    maxClaims: 500
)
```

### Create Airdrop Campaign
```cadence
admin.createAirdrop(
    name: "1K GUM Milestone",
    description: "Reached 1,000 GUM earned!",
    requiredGUM: 1000.0,
    requiredFlunks: true,
    minFlunksCount: 1,
    totalSupply: 200,
    achievementType: "gum_earner"
)
```

### Mint Achievement Directly
```cadence
admin.mintAchievement(
    recipient: 0x123...,
    achievementType: "early_supporter"
)
```

---

## 🎮 Frontend Integration

### Display Flunks with Dynamic Images

```typescript
// Get owner's Flunks with dynamic metadata
const flunksWithDynamic = await fcl.query({
  cadence: `
    import FlunksDynamicViews from 0x...
    
    access(all) fun main(owner: Address): [FlunksDynamicViews.FlunksNFTInfo] {
      return FlunksDynamicViews.getAllFlunksDynamic(ownerAddress: owner)
    }
  `,
  args: (arg, t) => [arg(userAddress, t.Address)]
});

// Each Flunks automatically has correct day/night image!
flunksWithDynamic.forEach(nft => {
  console.log(nft.name, nft.imageURL); // Shows day or night URL
});
```

### Display User Profile

```typescript
const stats = await fcl.query({
  cadence: `
    import FlunksDynamicViews from 0x...
    
    access(all) fun main(owner: Address): FlunksDynamicViews.OwnerStats? {
      return FlunksDynamicViews.getOwnerStats(ownerAddress: owner)
    }
  `,
  args: (arg, t) => [arg(userAddress, t.Address)]
});

console.log(`${stats.username} owns ${stats.flunksOwned} Flunks`);
console.log(`GUM Balance: ${stats.gumBalance}`);
console.log(`Achievements: ${stats.achievementsUnlocked}`);
console.log(`Local Time: ${stats.isDaytime ? 'Day' : 'Night'} (${stats.localHour}:00)`);
```

### Check Airdrop Eligibility

```typescript
const eligible = await fcl.query({
  cadence: `
    import SemesterZero from 0x...
    
    access(all) fun main(claimer: Address, airdropID: UInt64): Bool {
      return SemesterZero.checkAirdropEligibility(
        claimer: claimer,
        airdropID: airdropID
      )
    }
  `,
  args: (arg, t) => [
    arg(userAddress, t.Address),
    arg(airdropID, t.UInt64)
  ]
});

if (eligible) {
  // Show "Claim Airdrop" button
}
```

---

## 🏆 Hackathon Submission Points

### Innovation:
- ✅ Dynamic NFT metadata based on user timezone (novel use case)
- ✅ Evolving Achievement NFTs (metadata changes with balance)
- ✅ Hybrid on-chain/off-chain GUM system (NOT a token, but blockchain-tracked)
- ✅ Composable architecture (SemesterZero + FlunksDynamicViews + existing Flunks)

### Technical Sophistication:
- ✅ Resource-oriented programming (Cadence best practices)
- ✅ Dynamic metadata resolution
- ✅ Multi-contract interaction
- ✅ NFT gating (verify ownership on-chain)
- ✅ Time-based logic (timezone calculations)

### User Experience:
- ✅ Earn GUM on website (free, instant)
- ✅ Sync to blockchain (transparent, verifiable)
- ✅ Visual progression (NFTs evolve)
- ✅ Social features (transfer with messages)
- ✅ Gamification (achievements, airdrops, drops)

### Production-Ready:
- ✅ Cost optimization (hybrid sync strategy)
- ✅ Access control (entitlements)
- ✅ Event emission (tracking)
- ✅ Error handling (pre-conditions)
- ✅ Comprehensive testing paths

---

## 📝 Contract Deployment Order

1. **Deploy SemesterZero.cdc** first
2. **Deploy FlunksDynamicViews.cdc** second (depends on SemesterZero)
3. Update Flunks templates with `dayImageUri` and `nightImageUri` metadata

---

## 🎨 Asset Requirements

For each Flunks template, you'll need:
- `uri` - Default image (current)
- `dayImageUri` - Daytime variant (NEW)
- `nightImageUri` - Nighttime variant (NEW)

For Achievement NFTs, you'll need:
```
achievements/
  gum_earner_bronze.png
  gum_earner_silver.png
  gum_earner_gold.png
  gum_earner_platinum.png
  gum_earner_diamond.png
  tipper_newcomer.png
  tipper_supporter.png
  tipper_generous.png
  tipper_very_generous.png
  tipper_legendary_tipper.png
  spender_window_shopper.png
  spender_browser.png
  spender_customer.png
  spender_frequent_shopper.png
  spender_big_spender.png
  early_supporter_bronze.png (etc.)
```

---

## 🚀 Next Steps

1. **Review the contracts** - SemesterZero.cdc and FlunksDynamicViews.cdc
2. **Create day/night artwork** - For key Flunks templates
3. **Create achievement artwork** - For all tiers
4. **Deploy to testnet** - Test the full flow
5. **Build frontend components** - Profile, GUM balance, achievements
6. **Create demo video** - Show day/night switching live!

---

## 💡 Demo Script for Hackathon

```
1. Show user profile with timezone (PST -8)
2. Current time: 10 AM PST → Flunks shows daytime artwork
3. User has 750 GUM → Achievement NFT shows "Silver" tier
4. User transfers 50 GUM to friend → Transaction on blockchain
5. User claims special drop → Earns 50 GUM
6. User now has 800 GUM → Achievement automatically upgrades artwork!
7. Change timezone to Tokyo (+9) → Time is now 2 AM → Flunks shows nighttime artwork!
8. User eligible for "1K Milestone" airdrop → Claims → Mints Achievement NFT
```

**This demonstrates:**
- Dynamic metadata (day/night)
- Evolving NFTs (tier upgrades)
- Hybrid GUM system (earn + sync + transfer)
- Social features (transfers)
- Gamification (drops, airdrops)
- Real-time updates

---

## 🎉 Summary

**Semester Zero** is a complete ecosystem that combines:
- GUM rewards system (hybrid on-chain/off-chain)
- Dynamic time-based NFT artwork
- Evolving achievement NFTs
- Social features (transfers, tipping)
- Gamification (drops, airdrops, milestones)

**All in one unified contract!** 🚀

Perfect for the Forte Hackathon 2025! 🏆
