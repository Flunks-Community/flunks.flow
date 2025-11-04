# ✅ NFT Airdrops - You're Ready!

## Quick Answer

**Question:** "so we need to start a collection on flow i guess if i'm going to airdrop users new NFT's?"

**Answer:** ✅ **The collection is ALREADY BUILT into SemesterZero!**

When users run the setup transaction, they get:
- User Profile ✅
- GUM Account ✅
- **Achievement Collection** ✅ ← Ready for airdrops!

---

## 🎁 How Airdrops Work

### 1. Admin Creates Airdrop Campaign

```bash
flow transactions send ./cadence/transactions/semester-zero/admin-create-airdrop.cdc \
  --arg String:"Early Adopter Badge" \
  --arg String:"You were here at the beginning!" \
  --arg UFix64:100.0 \
  --arg Bool:true \
  --arg Int:1 \
  --arg UInt64:500 \
  --arg String:"early_supporter"
```

**This creates:**
- Name: "Early Adopter Badge"
- Requirement: 100 GUM + 1 Flunks
- Supply: 500 NFTs
- Type: Achievement NFT (evolves with GUM)

### 2. Users Check Eligibility

```bash
flow scripts execute ./cadence/scripts/semester-zero/check-airdrop-eligibility.cdc \
  --arg Address:0x123... \
  --arg UInt64:1
```

**Returns:**
```json
{
  "isEligible": true,
  "reason": "✅ Eligible to claim!",
  "airdropName": "Early Adopter Badge",
  "requiredGUM": 100.0,
  "requiredFlunks": true,
  "minFlunksCount": 1
}
```

### 3. Users Claim (Mints Achievement NFT)

```bash
flow transactions send ./cadence/transactions/semester-zero/claim-airdrop.cdc \
  --arg UInt64:1
```

**Mints Achievement NFT into user's collection!**

---

## 🏆 What Gets Airdropped

**Achievement NFTs** - Evolving badges that upgrade automatically!

### Examples:

#### "Early Adopter" Achievement
- **Bronze** (100 GUM): Shows bronze badge
- **Silver** (500 GUM): Badge automatically upgrades to silver
- **Gold** (1000 GUM): Badge automatically upgrades to gold
- **Platinum** (5000 GUM): Badge automatically upgrades to platinum
- **Diamond** (10000 GUM): Badge automatically upgrades to diamond

#### "GUM Earner" Achievement
- Tracks total GUM earned
- Evolves through same tiers
- Shows progression visually

#### "OG Flunks" Achievement
- For early Flunks holders
- Can gate by number of Flunks owned
- Custom progression tiers

---

## 📋 Files Created

### Transactions:
✅ **`cadence/transactions/semester-zero/admin-create-airdrop.cdc`**
   - Admin creates airdrop campaigns
   - Includes 4 example commands

✅ **`cadence/transactions/semester-zero/claim-airdrop.cdc`**
   - Users claim airdrops
   - Mints Achievement NFT

### Scripts:
✅ **`cadence/scripts/semester-zero/check-airdrop-eligibility.cdc`**
   - Check if user can claim
   - Returns reason if not eligible

### Documentation:
✅ **`docs/NFT-AIRDROP-GUIDE.md`**
   - Complete airdrop guide
   - Explains options and recommendations

---

## 🎨 What You Need to Create

### Achievement Artwork (5 tiers each)

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

**Upload to:**
```
https://storage.googleapis.com/flunks_public/achievements/
```

---

## 🚀 Deployment Flow

### Step 1: Deploy Contract
```bash
flow accounts add-contract SemesterZero ./cadence/contracts/SemesterZero.cdc
```

### Step 2: Users Setup (One-Time)
```bash
flow transactions send ./cadence/transactions/semester-zero/setup-complete.cdc \
  --arg String:"jeremy" \
  --arg Int:-8
```

Creates Achievement Collection ✅

### Step 3: Admin Creates Airdrops
```bash
# Early Adopter
flow transactions send ./cadence/transactions/semester-zero/admin-create-airdrop.cdc \
  --arg String:"Early Adopter Badge" \
  --arg String:"You were here at the beginning!" \
  --arg UFix64:100.0 \
  --arg Bool:true \
  --arg Int:1 \
  --arg UInt64:500 \
  --arg String:"early_supporter"

# GUM Whale
flow transactions send ./cadence/transactions/semester-zero/admin-create-airdrop.cdc \
  --arg String:"GUM Whale Trophy" \
  --arg String:"Earned 10,000+ GUM!" \
  --arg UFix64:10000.0 \
  --arg Bool:false \
  --arg Int:0 \
  --arg UInt64:50 \
  --arg String:"gum_earner"

# OG Flunks Holder
flow transactions send ./cadence/transactions/semester-zero/admin-create-airdrop.cdc \
  --arg String:"OG Flunks Holder" \
  --arg String:"True Flunks collector!" \
  --arg UFix64:500.0 \
  --arg Bool:true \
  --arg Int:5 \
  --arg UInt64:200 \
  --arg String:"og_flunks"
```

### Step 4: Users Claim
```bash
flow transactions send ./cadence/transactions/semester-zero/claim-airdrop.cdc \
  --arg UInt64:1
```

---

## 💻 Frontend Integration

### Check Eligibility
```typescript
const eligibility = await fcl.query({
  cadence: `
    import SemesterZero from 0x...
    
    access(all) fun main(user: Address, airdropID: UInt64): Bool {
      return SemesterZero.checkAirdropEligibility(
        claimer: user,
        airdropID: airdropID
      )
    }
  `,
  args: (arg, t) => [
    arg(userAddress, t.Address),
    arg("1", t.UInt64)
  ]
});

if (eligibility) {
  // Show "Claim Airdrop" button
}
```

### Get All Active Airdrops
```typescript
const airdrops = await fcl.query({
  cadence: `
    import SemesterZero from 0x...
    
    access(all) fun main(): [SemesterZero.AirdropInfo] {
      return SemesterZero.getActiveAirdrops()
    }
  `
});

airdrops.forEach(airdrop => {
  console.log(airdrop.name);
  console.log(`Required GUM: ${airdrop.requiredGUM}`);
  console.log(`Supply: ${airdrop.claimCount}/${airdrop.totalSupply}`);
});
```

### Claim Airdrop
```typescript
const txId = await fcl.mutate({
  cadence: `
    import SemesterZero from 0x...
    
    transaction(airdropID: UInt64) {
      prepare(signer: auth(Storage) &Account) {
        let collection = signer.storage.borrow<&SemesterZero.AchievementCollection>(
          from: SemesterZero.AchievementCollectionStoragePath
        ) ?? panic("No achievement collection")
        
        let nftID = SemesterZero.claimAirdrop(
          airdropID: airdropID,
          claimer: signer.address,
          achievementCollection: collection
        )
        
        log("Minted Achievement NFT #".concat(nftID.toString()))
      }
    }
  `,
  args: (arg, t) => [arg("1", t.UInt64)]
});

await fcl.tx(txId).onceSealed();
console.log("✅ Airdrop claimed!");
```

---

## 🎯 Example Airdrop Campaigns

### Campaign 1: "Early Adopter"
- **Target:** First movers
- **Requirement:** 100 GUM + 1 Flunks
- **Supply:** 500
- **Message:** "You were here from the start!"

### Campaign 2: "GUM Whale"
- **Target:** Top earners
- **Requirement:** 10,000 GUM
- **Supply:** 50
- **Message:** "Elite tier reached!"

### Campaign 3: "OG Flunks Collector"
- **Target:** Serious collectors
- **Requirement:** 500 GUM + 5 Flunks
- **Supply:** 200
- **Message:** "True Flunks enthusiast!"

### Campaign 4: "Hackathon Participant"
- **Target:** Everyone
- **Requirement:** 1 GUM
- **Supply:** 10,000
- **Message:** "Thank you for participating in Forte 2025!"

---

## ✅ Summary

**You asked:** "do we need to start a collection on flow?"

**Answer:**

🎉 **NO! The Achievement Collection is already built into SemesterZero!**

**What's ready:**
- ✅ AchievementNFT resource (the NFT itself)
- ✅ AchievementCollection resource (users' collection)
- ✅ Airdrop system (GUM-gated claiming)
- ✅ Admin functions (create airdrops)
- ✅ User functions (claim airdrops)
- ✅ Eligibility checking
- ✅ Setup transaction
- ✅ Dynamic metadata (evolving tiers)

**What you need:**
- 🎨 Create achievement artwork (all tiers)
- 🚀 Deploy SemesterZero contract
- 🎁 Create airdrop campaigns
- 💻 Build frontend claim UI

**You're ready to airdrop!** 🚀
