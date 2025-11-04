# What Does "User Setup" Mean? 🤔

**Date**: October 20, 2025  
**Question**: "what do you mean user setup and create profile? + NFT?"

---

## ✅ What Users ALREADY Have

Your users already have these things set up:

1. **✅ Flow Wallet** - They have wallets
2. **✅ Flunks NFT Collection** - Already initialized for Flunks NFTs
3. **✅ Backpack NFT Collection** - Already initialized for Backpacks
4. **✅ Supabase Profile** - Database records (wallet_address, username, etc.)
5. **✅ Website Account** - They can log in and play

**You DON'T need to recreate any of this!** 👍

---

## 🆕 What's NEW for SemesterZero_Hackathon

The **SemesterZero_Hackathon.cdc** contract introduces **3 new things on the blockchain** that users don't have yet:

### 1. **UserProfile Resource** (for timezone/day-night)
```cadence
// This is NEW - stores timezone on blockchain
access(all) resource UserProfile {
    access(all) let username: String
    access(all) var timezone: Int  // NEW! For day/night image
    
    // Returns true if it's daytime (6 AM - 6 PM) in user's timezone
    access(all) fun isDaytime(): Bool {
        // Magic calculation based on user's timezone
    }
}
```

**Why?** So the contract knows if it's day or night **in the user's timezone** to show the right Paradise Motel image.

### 2. **Chapter5NFT Collection** (for achievement NFTs)
```cadence
// This is NEW - separate collection for Chapter 5 achievement NFTs
access(all) resource Chapter5Collection {
    access(all) var ownedNFTs: @{UInt64: Chapter5NFT}
    // Stores the Chapter 5 completion NFT
}
```

**Why?** The Chapter 5 achievement NFT is **separate from Flunks NFTs**. It's a special achievement NFT for completing objectives.

### 3. **Chapter5Status** (completion tracking)
```cadence
// This is NEW - tracks completion on blockchain
access(all) struct Chapter5Status {
    access(all) var slackerComplete: Bool       // Room 7 key obtained
    access(all) var overachieverComplete: Bool  // Overachiever task done
    access(all) var nftAirdropped: Bool         // NFT sent
}
```

**Why?** This is stored **on the blockchain** (not just Supabase) so the NFT airdrop is trustless and permanent.

---

## 🤔 Do Users Actually Need to "Set Up" Anything?

**YES, but only once!** When a user first interacts with the SemesterZero hackathon features:

### **Option A: Auto-Setup in Website (RECOMMENDED)**

The **website backend** can auto-setup everything when the user first logs in:

```typescript
// app/api/hackathon/setup/route.ts

export async function POST(req: Request) {
  const { walletAddress, timezone } = await req.json();
  
  // Check if already setup
  const hasProfile = await fcl.query({
    cadence: CHECK_PROFILE_SCRIPT,
    args: (arg, t) => [arg(walletAddress, t.Address)]
  });
  
  if (!hasProfile) {
    // Auto-setup user profile + collection
    await fcl.mutate({
      cadence: SETUP_ALL_TRANSACTION,
      args: (arg, t) => [
        arg(timezone, t.Int)  // Get from browser
      ],
      authorizations: [fcl.currentUser]  // User signs
    });
  }
  
  return Response.json({ success: true });
}
```

**User flow:**
1. User logs in with wallet → Website gets their timezone from browser
2. Website checks: "Do they have SemesterZero profile?"
3. If NO → Website prompts: "Sign this transaction to enable hackathon features"
4. User signs **once** → Profile + Collection created
5. Done! Never need to do it again ✅

---

### **Option B: Manual Setup (Not Recommended)**

User runs a transaction manually:

```cadence
// setup-hackathon-account.cdc
transaction(timezone: Int) {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // 1. Create profile
        let profile <- SemesterZero.createUserProfile(
            username: "FlunksUser",
            timezone: timezone
        )
        signer.storage.save(<-profile, to: SemesterZero.UserProfileStoragePath)
        
        // 2. Create Chapter 5 collection
        let collection <- SemesterZero.createEmptyChapter5Collection()
        signer.storage.save(<-collection, to: SemesterZero.Chapter5CollectionStoragePath)
    }
}
```

**User flow:**
1. User navigates to special setup page
2. User clicks "Set Up Hackathon Features"
3. User signs transaction manually
4. Done ✅

---

## 📊 Comparison: What's Different?

| Feature | Existing System | Hackathon System |
|---------|----------------|------------------|
| **Flunks NFTs** | ✅ Already have collection | ✅ Keep using existing |
| **Backpack NFTs** | ✅ Already have collection | ✅ Keep using existing |
| **Supabase Profile** | ✅ Already exists | ✅ Keep using existing |
| **Timezone** | ❌ Not on blockchain | 🆕 NEW! Stored in UserProfile |
| **Chapter 5 Status** | ✅ In Supabase only | 🆕 ALSO on blockchain now |
| **Chapter 5 NFT** | ❌ Doesn't exist yet | 🆕 NEW! Achievement NFT |

---

## 🎯 What You Actually Need to Build

### **1. One-Time Setup Transaction**
```cadence
// cadence/transactions/hackathon/setup-all.cdc
// User runs ONCE when they first use hackathon features

transaction(timezone: Int) {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Create profile (if doesn't exist)
        if signer.storage.type(at: SemesterZero.UserProfileStoragePath) == nil {
            let profile <- SemesterZero.createUserProfile(
                username: "FlunksUser",  // Or get from Supabase
                timezone: timezone
            )
            signer.storage.save(<-profile, to: SemesterZero.UserProfileStoragePath)
            
            let cap = signer.capabilities.storage.issue<&SemesterZero.UserProfile>(
                SemesterZero.UserProfileStoragePath
            )
            signer.capabilities.publish(cap, at: SemesterZero.UserProfilePublicPath)
        }
        
        // Create Chapter 5 collection (if doesn't exist)
        if signer.storage.type(at: SemesterZero.Chapter5CollectionStoragePath) == nil {
            let collection <- SemesterZero.createEmptyChapter5Collection()
            signer.storage.save(<-collection, to: SemesterZero.Chapter5CollectionStoragePath)
            
            let cap = signer.capabilities.storage.issue<&{NonFungibleToken.Receiver}>(
                SemesterZero.Chapter5CollectionStoragePath
            )
            signer.capabilities.publish(cap, at: SemesterZero.Chapter5CollectionPublicPath)
        }
    }
}
```

### **2. Check Script**
```cadence
// cadence/scripts/hackathon/check-setup.cdc
// Check if user has setup hackathon features

import SemesterZero from "../../contracts/SemesterZero_Hackathon.cdc"

access(all) fun main(userAddress: Address): {String: Bool} {
    let account = getAccount(userAddress)
    
    let hasProfile = account.storage.type(at: SemesterZero.UserProfileStoragePath) != nil
    let hasCollection = account.storage.type(at: SemesterZero.Chapter5CollectionStoragePath) != nil
    
    return {
        "hasProfile": hasProfile,
        "hasCollection": hasCollection,
        "isFullySetup": hasProfile && hasCollection
    }
}
```

### **3. Website API Endpoint**
```typescript
// app/api/hackathon/setup/route.ts

import * as fcl from '@onflow/fcl';

export async function POST(req: Request) {
  const { walletAddress } = await req.json();
  
  // Get timezone from browser (or Supabase if already stored)
  const timezone = new Date().getTimezoneOffset() / -60;
  
  // Check if already setup
  const setupStatus = await fcl.query({
    cadence: CHECK_SETUP_SCRIPT,
    args: (arg, t) => [arg(walletAddress, t.Address)]
  });
  
  if (setupStatus.isFullySetup) {
    return Response.json({ 
      success: true, 
      message: 'Already setup' 
    });
  }
  
  // Trigger setup transaction
  // User will sign in their wallet
  const txId = await fcl.mutate({
    cadence: SETUP_ALL_TRANSACTION,
    args: (arg, t) => [arg(timezone, t.Int)],
    authorizations: [fcl.currentUser]
  });
  
  // Wait for transaction
  await fcl.tx(txId).onceSealed();
  
  return Response.json({ 
    success: true, 
    message: 'Setup complete',
    txId 
  });
}
```

---

## 🚀 Simple User Experience

### **When User First Visits Hackathon Features:**

```
User logs in with wallet
    ↓
Website checks: "Do they have hackathon setup?"
    ↓
NO → Show popup:
    "🎉 Welcome to Semester Zero! 
     Sign this transaction to unlock hackathon features.
     (You only need to do this once!)"
    ↓
User clicks "Sign Transaction"
    ↓
[Wallet popup appears]
    ↓
User approves in wallet
    ↓
✅ Done! Profile + Collection created
    ↓
User can now:
    - See day/night Paradise Motel based on their timezone
    - Complete Room 7 objective
    - Receive Chapter 5 NFT when both objectives done
```

---

## ✅ Summary

**What "user setup" means:**

1. **Create UserProfile** - Stores timezone on blockchain for day/night feature
2. **Create Chapter5Collection** - Stores achievement NFT collection

**How it works:**

- Users sign **ONE transaction** when they first use hackathon features
- Website auto-detects timezone from browser
- Setup takes 5 seconds
- Never need to do it again

**What users DON'T need:**

- ❌ Don't need to create new Flow wallet (already have one)
- ❌ Don't need to setup Flunks NFT collection (already have it)
- ❌ Don't need to setup Supabase profile (already have it)

**Just these 2 new blockchain resources:**
- ✅ UserProfile (timezone)
- ✅ Chapter5Collection (achievement NFT)

---

## 💡 Even Simpler Option: Skip User Profile?

**Actually... do we even need UserProfile on blockchain?**

The timezone could be stored in **Supabase only** and the contract just returns image URLs based on what the website tells it.

**Alternative approach:**
```typescript
// Website calculates day/night (no blockchain storage)
const userTimezone = new Date().getTimezoneOffset() / -60;
const localHour = (new Date().getUTCHours() + userTimezone + 24) % 24;
const isDaytime = localHour >= 6 && localHour < 18;

const imageUrl = isDaytime 
  ? 'paradise-motel-day.png' 
  : 'paradise-motel-night.png';
```

**Then users only need:**
- ✅ Chapter5Collection (for achievement NFT)

**Setup is even simpler!**

---

Want me to create the simplified version with **only** Chapter5Collection setup? Or keep UserProfile for the cool "timezone on blockchain" demo?
