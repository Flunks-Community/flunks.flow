# 🎓 Semester Zero - Quick Start

## ✅ What We Created

### **Main Unified Contract:**
- **`SemesterZero.cdc`** (1,000+ lines)
  - GUM system (hybrid on-chain ledger)
  - User profiles with timezone
  - Dynamic Achievement NFTs (evolve with GUM)
  - Special drops (time-limited events)
  - GUM-gated airdrops
  - Admin controls

### **Dynamic Views Wrapper:**
- **`FlunksDynamicViews.cdc`**
  - Day/night image switching based on user timezone
  - Aggregates stats from SemesterZero + Flunks
  - Display helper functions

### **Setup Transaction:**
- **`cadence/transactions/semester-zero/setup-complete.cdc`**
  - One transaction to set up everything
  - Creates: Profile + GUM Account + Achievement Collection

---

## 🌟 Key Features

### 1. ⏰ **Time-Based Dynamic NFTs**
Your Flunks show different artwork based on YOUR local time!

```cadence
// User creates profile with timezone
createUserProfile(username: "jeremy", timezone: -8) // PST

// Profile automatically calculates local time
profile.isDaytime() // true if 6 AM - 6 PM in YOUR timezone
profile.getLocalHour() // Returns local hour (0-23)

// Flunks NFT checks and shows day or night image
// No manual refreshing needed!
```

**Requirements:**
- Each Flunks template needs 3 image URLs:
  - `uri` - Default (existing)
  - `dayImageUri` - Daytime artwork (NEW)
  - `nightImageUri` - Nighttime artwork (NEW)

### 2. 🏆 **Evolving Achievement NFTs**
NFTs that automatically upgrade appearance as you earn GUM!

**Types:**
- **GUM Earner**: Bronze → Silver → Gold → Platinum → Diamond
- **Tipper**: Newcomer → Supporter → Generous → Very Generous → Legendary
- **Spender**: Window Shopper → Browser → Customer → Frequent Shopper → Big Spender

```cadence
// User has 750 GUM earned
achievementNFT.getCurrentTier() // "Silver"

// User earns more GUM (now 1500 total)
achievementNFT.getCurrentTier() // "Gold" ← Automatically upgraded!

// Image URL changes automatically
// "https://.../achievements/gum_earner_gold.png"
```

### 3. 🎁 **GUM-Gated Airdrops**
Unlock exclusive Achievement NFTs by reaching GUM milestones!

```cadence
// Check eligibility
SemesterZero.checkAirdropEligibility(claimer: 0x123..., airdropID: 1)
// Returns true if: GUM >= required && Flunks >= required && not already claimed

// Claim airdrop (mints Achievement NFT)
SemesterZero.claimAirdrop(airdropID: 1, claimer: 0x123..., collection: &collection)
```

### 4. 🎉 **Special Drops**
Time-limited GUM drops with NFT gating:

```cadence
// Create weekend bonus
admin.createSpecialDrop(
    name: "Weekend Bonus",
    amount: 50.0, // 50 GUM
    startTime: fridayTimestamp,
    endTime: sundayTimestamp,
    requiredFlunks: true,
    minFlunksCount: 1,
    maxClaims: 1000
)

// User claims
SemesterZero.claimSpecialDrop(dropID: 1, gumAccount: &gumAccount)
```

---

## 🚀 Deployment Steps

### 1. Deploy Contracts

```bash
# Deploy SemesterZero first
flow accounts add-contract SemesterZero ./cadence/contracts/SemesterZero.cdc

# Deploy FlunksDynamicViews second (depends on SemesterZero)
flow accounts add-contract FlunksDynamicViews ./cadence/contracts/FlunksDynamicViews.cdc
```

### 2. User Setup (One Transaction)

```bash
flow transactions send ./cadence/transactions/semester-zero/setup-complete.cdc \
  --arg String:"jeremy" \
  --arg Int:-8
```

This creates:
- ✅ User profile with timezone
- ✅ GUM account (starting balance: 0)
- ✅ Achievement collection (empty)

### 3. Admin Setup

```cadence
// Admin resource already saved during contract init
// Located at: /storage/SemesterZeroAdmin

// Admin can now:
// - Sync GUM balances from Supabase
// - Create special drops
// - Create airdrops
// - Mint achievements
```

---

## 📊 User Flow Example

```
1. User signs up on website
   ↓
2. User runs setup transaction (profile + GUM account + achievement collection)
   ↓
3. User earns GUM on website (Supabase)
   - Daily login: +10 GUM
   - Daily checkin: +5 GUM
   - Complete quest: +25 GUM
   ↓
4. Admin syncs to blockchain (once per day or at milestones)
   admin.syncUserBalance(userAddress: 0x123..., newBalance: 150.0)
   ↓
5. User views their Flunks NFT
   - It's 2 PM in their timezone → Shows daytime artwork ☀️
   ↓
6. User transfers GUM to friend
   gumAccount.transfer(amount: 10.0, to: 0x456..., message: "Thanks!")
   ↓
7. User reaches 1000 GUM
   - Checks airdrop: checkAirdropEligibility() → true
   - Claims airdrop: claimAirdrop() → Mints "Gold GUM Earner" Achievement NFT
   ↓
8. Achievement NFT evolves
   - 750 GUM → Shows "Silver" artwork
   - 1500 GUM → Shows "Gold" artwork (automatic upgrade!)
   ↓
9. User checks Flunks at night (10 PM)
   - Shows nighttime artwork 🌙
```

---

## 🎨 Asset Requirements

### Day/Night Flunks Images

For each Flunks template you want to have dynamic images:

```json
{
  "name": "Flunks #42",
  "uri": "https://storage.googleapis.com/flunks_public/flunks/42.png",
  "dayImageUri": "https://storage.googleapis.com/flunks_public/flunks/42_day.png",
  "nightImageUri": "https://storage.googleapis.com/flunks_public/flunks/42_night.png"
}
```

### Achievement Images

Structure: `achievements/{type}_{tier}.png`

```
achievements/
├── gum_earner_bronze.png
├── gum_earner_silver.png
├── gum_earner_gold.png
├── gum_earner_platinum.png
├── gum_earner_diamond.png
├── tipper_newcomer.png
├── tipper_supporter.png
├── tipper_generous.png
├── tipper_very_generous.png
├── tipper_legendary_tipper.png
├── spender_window_shopper.png
├── spender_browser.png
├── spender_customer.png
├── spender_frequent_shopper.png
└── spender_big_spender.png
```

---

## 🎯 Hackathon Demo Flow

**"Living NFTs that Grow with You"**

### Setup (Show Once)
```
1. User creates profile with PST timezone (-8)
2. Current time: 10 AM PST
3. User has 0 GUM
```

### Demo Flow
```
✅ Show Flunks NFT → Displays daytime artwork (it's 10 AM)

✅ User earns 750 GUM on website → Admin syncs to blockchain

✅ User claims "Early Adopter" airdrop → Mints Achievement NFT (Bronze tier)

✅ Achievement automatically shows "Bronze" artwork

✅ User transfers 50 GUM to friend → On-chain transaction (transparent)

✅ User earns more GUM (now 1500 total)

✅ Achievement AUTOMATICALLY upgrades → Now shows "Gold" artwork

✅ User claims "Weekend Bonus" special drop → Earns 50 more GUM

✅ Switch timezone to Tokyo (+9) → Time is now 2 AM Tokyo time

✅ Flunks NFT AUTOMATICALLY switches → Now shows nighttime artwork

✅ Switch back to PST → Back to daytime artwork
```

**Key Points:**
- 🌍 Dynamic metadata changes in REAL-TIME
- 📈 NFTs evolve as you progress
- 🤝 Social features (transparent transfers)
- 🎁 Gamification (drops, airdrops, milestones)
- 💰 Cost-effective (hybrid on-chain/off-chain)

---

## 💻 Frontend Queries

### Get User's Dynamic Flunks

```typescript
import * as fcl from "@onflow/fcl"

// Get all Flunks with dynamic day/night images
const flunks = await fcl.query({
  cadence: `
    import FlunksDynamicViews from 0x...
    
    access(all) fun main(owner: Address): [FlunksDynamicViews.FlunksNFTInfo] {
      return FlunksDynamicViews.getAllFlunksDynamic(ownerAddress: owner)
    }
  `,
  args: (arg, t) => [arg(userAddress, t.Address)]
});

// Each Flunks has the correct day/night image!
flunks.forEach(nft => {
  console.log(nft.name); // "Flunks #42"
  console.log(nft.imageURL); // Day or night URL based on user's timezone
});
```

### Get User Stats

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

console.log(`Username: ${stats.username}`);
console.log(`Flunks Owned: ${stats.flunksOwned}`);
console.log(`GUM Balance: ${stats.gumBalance}`);
console.log(`Total Earned: ${stats.gumTotalEarned}`);
console.log(`Achievements: ${stats.achievementsUnlocked}`);
console.log(`Local Time: ${stats.localHour}:00 ${stats.isDaytime ? '☀️' : '🌙'}`);
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
    arg("1", t.UInt64)
  ]
});

if (eligible) {
  // Show "Claim Airdrop" button
}
```

### Get Active Drops

```typescript
const drops = await fcl.query({
  cadence: `
    import SemesterZero from 0x...
    
    access(all) fun main(): [SemesterZero.SpecialDropInfo] {
      return SemesterZero.getActiveDrops()
    }
  `
});

drops.forEach(drop => {
  console.log(`${drop.name}: ${drop.amount} GUM`);
  console.log(`Ends: ${new Date(drop.endTime * 1000)}`);
});
```

---

## 🏆 Why This Wins the Hackathon

### Novel Features:
- ✅ Time-based dynamic NFTs (shows different art based on YOUR timezone)
- ✅ Evolving Achievement NFTs (upgrade appearance automatically)
- ✅ GUM as utility without being a token (hybrid ledger)

### Technical Excellence:
- ✅ Resource-oriented programming (Cadence best practices)
- ✅ Composable architecture (multiple contracts working together)
- ✅ Dynamic metadata resolution
- ✅ Multi-contract state aggregation

### Production-Ready:
- ✅ Cost optimization (hybrid sync strategy)
- ✅ Access control (entitlements)
- ✅ Event emission (tracking)
- ✅ Error handling (comprehensive pre-conditions)

### User Experience:
- ✅ Visual progression (NFTs evolve)
- ✅ Social features (transfers with messages)
- ✅ Gamification (drops, airdrops, achievements)
- ✅ Personalized (timezone-based rendering)

---

## 📝 Files Created

```
cadence/
├── contracts/
│   ├── SemesterZero.cdc (NEW - 1,000+ lines)
│   ├── FlunksDynamicViews.cdc (NEW - 200+ lines)
│   └── GumDropsHybrid.cdc (existing - standalone version)
└── transactions/
    └── semester-zero/
        └── setup-complete.cdc (NEW)

docs/
├── SEMESTER-ZERO-COMPLETE.md (NEW - comprehensive guide)
├── SEMESTER-ZERO-QUICKSTART.md (NEW - this file)
└── FORTE-HACKATHON-IDEAS.md (existing - brainstorm)
```

---

## 🎉 Ready to Build!

You now have:
- ✅ Unified contract with all features
- ✅ Day/night dynamic NFTs
- ✅ Evolving Achievement NFTs  
- ✅ GUM system (hybrid)
- ✅ Special drops & airdrops
- ✅ User profiles with timezones
- ✅ Setup transaction
- ✅ Comprehensive documentation

**Next:** Deploy to testnet and create the artwork! 🚀
