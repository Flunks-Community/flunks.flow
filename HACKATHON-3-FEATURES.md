# SemesterZero - Forte Hackathon Features

**Date**: October 20, 2025  
**3 Core Features for Hackathon**

---

## 🎯 What We're Building

### **Feature 1: Gum Drop Airdrop (48-hour claim window)**
- Admin triggers airdrop → Marks users eligible on blockchain
- Website shows popup: "You have 100 GUM to claim!"
- User clicks "Claim" (48-hour window)
- GUM added to Supabase (just like daily "Claim 15 GUM")
- Blockchain marks claimed = true

### **Feature 2: Day/Night Cycles (per user timezone)**
- Each user has timezone in their profile
- 12-hour cycles: 6 AM - 6 PM = day, 6 PM - 6 AM = night
- Paradise Motel level shows different image based on user's local time
- Same moment = different images for different users

### **Feature 3: Chapter 5 NFT Airdrop**
- User completes Slacker objective (tracked in Supabase)
- User completes Overachiever objective (tracked in Supabase)
- When BOTH complete → Auto-airdrop NFT to their wallet
- NFT goes in "SemesterZero Collection" (new collection we'll create)

---

## 🏗️ Architecture

```
SemesterZero Contract (ONE contract, all features):
├── 1. Gum Drop System
│   ├── GumDrop struct (eligibility + 48hr window)
│   ├── Admin: createGumDrop(addresses[], amount, duration)
│   ├── Admin: markGumClaimed(user)
│   └── Events: GumDropCreated, GumClaimed
│
├── 2. User Profile (timezone)
│   ├── UserProfile resource (timezone: Int)
│   ├── getLocalHour() → calculates user's time
│   ├── isDaytime() → true if 6 AM - 6 PM
│   └── Events: ProfileCreated, ProfileUpdated
│
└── 3. Chapter 5 NFT Collection
    ├── Chapter5NFT resource (achievement NFT)
    ├── Chapter5Collection resource (holds NFTs)
    ├── Chapter5Status struct (tracks slacker + overachiever)
    ├── Admin: registerCompletion(user, type)
    ├── Admin: airdropNFT(user) → auto when both complete
    └── Events: CompletionRegistered, NFTAirdropped
```

---

## 📝 Feature Details

### **1. Gum Drop Airdrop System**

#### **Flow:**
```
Day 1:
- Admin triggers: createGumDrop(users[], 100 GUM, 48 hours)
- Blockchain marks 1000 users as eligible
- Supabase syncs eligibility list

User visits website:
- Query: "Is this user eligible AND within 48hrs?"
- Show popup: "🎃 Claim Your 100 GUM! (47 hours left)"
- User clicks "Claim"
- Supabase: total_gum += 100 (instant!)
- Blockchain: markGumClaimed(user) → claimed = true
- Popup closes, balance updates

Day 3 (48 hours later):
- Window expires
- Unclaimed drops = lost opportunity
```

#### **Key Differences from Halloween:**
- ✅ Same eligibility tracking on blockchain
- ✅ Same Supabase GUM storage
- ⏰ **48-hour window** instead of 7 days
- 🔄 **Reusable** (can do multiple drops, not just Halloween)

---

### **2. Day/Night Per-User Timezone**

#### **Flow:**
```
User signs up:
- Creates UserProfile with timezone (e.g., -5 for EST)
- Stored on blockchain in their account

User views Paradise Motel:
- Website queries: SemesterZero.getUserDayNightStatus(userAddress)
- Blockchain calculates: local_hour = utc_hour + user.timezone
- Returns: isDaytime = (local_hour >= 6 && local_hour < 18)
- Website shows:
  - If daytime → paradise-motel-day.png
  - If nighttime → paradise-motel-night.png

Same moment, different users:
- User A (NYC, UTC-5): 10 AM local → Day image ☀️
- User B (Tokyo, UTC+9): 12 AM local → Night image 🌙
```

#### **Key Differences from Your Current System:**
- ❌ **Not global** (no central time for everyone)
- ✅ **Per user** (each user sees based on THEIR timezone)
- ✅ **Dynamic** (calculated every query, not scheduled action)
- ✅ **12-hour cycles** (same 6 AM - 6 PM rule)

---

### **3. Chapter 5 NFT Airdrop**

#### **Flow:**
```
User plays Chapter 5:
- Completes Slacker objective → Supabase logs completion
- API calls: SemesterZero.registerSlackerCompletion(userAddress)
- Blockchain marks: slackerComplete = true

- Completes Overachiever objective → Supabase logs completion  
- API calls: SemesterZero.registerOverachieverCompletion(userAddress)
- Blockchain marks: overachieverComplete = true

When BOTH complete:
- Blockchain auto-checks: "Both done?"
- Emits: Chapter5CompletionRegistered event
- Admin (or automated Flow Actions) calls: airdropChapter5NFT(userAddress)
- NFT minted and deposited to user's SemesterZero Collection
- User sees NFT in wallet + "My Locker" page
```

#### **NFT Collection:**
- **New collection**: "SemesterZero Collection"
- **Stored in**: Same SemesterZero contract (not separate!)
- **NFT Type**: Chapter5NFT (achievement type, metadata, timestamp)
- **User Setup**: Users must initialize collection first (one-time)

---

## 🔧 What to Remove from Current Contracts

### **From Version B (this repo) - REMOVE:**
- ❌ GumAccount resource (no balance tracking)
- ❌ transfer() function (no peer-to-peer GUM)
- ❌ deposit() function (GUM stays in Supabase only)
- ❌ VirtualGumVault (no Flow Actions needed yet)
- ❌ SemesterZeroFlowActions contract (skip for now)
- ❌ SpecialDrop resource (use simpler GumDrop)
- ❌ Airdrop resource (just use Chapter 5)
- ❌ AchievementNFT (just Chapter5NFT)

### **From Version A (flunks-site) - KEEP:**
- ✅ Chapter5Status struct
- ✅ Chapter5 completion tracking
- ✅ NFT minting logic
- ✅ Admin functions for completions

### **NEW to add:**
- ✅ UserProfile with timezone
- ✅ isDaytime() per-user calculation
- ✅ GumDrop struct (48-hour claim window)
- ✅ Gum eligibility tracking (like Halloween)

---

## 📊 Simplified Contract Structure

```cadence
access(all) contract SemesterZero {
    
    // PATHS
    access(all) let UserProfileStoragePath: StoragePath
    access(all) let UserProfilePublicPath: PublicPath
    access(all) let Chapter5CollectionStoragePath: StoragePath
    access(all) let Chapter5CollectionPublicPath: PublicPath
    access(all) let AdminStoragePath: StoragePath
    
    // STATE
    access(all) var totalProfiles: UInt64
    access(all) var totalChapter5NFTs: UInt64
    access(all) var activeGumDrop: GumDrop?
    access(all) let chapter5Completions: {Address: Chapter5Status}
    
    // STRUCTS
    access(all) struct GumDrop {
        // Eligibility tracker (48-hour window)
        access(all) let dropId: String
        access(all) let amount: UFix64
        access(all) let startTime: UFix64
        access(all) let endTime: UFix64  // startTime + 48 hours
        access(all) let eligibleUsers: {Address: Bool}
        access(all) var claimedUsers: {Address: UFix64}
        
        init(dropId: String, amount: UFix64, eligibleUsers: [Address], durationSeconds: UFix64)
        
        access(all) fun isEligible(user: Address): Bool
        access(all) fun hasClaimed(user: Address): Bool
        access(all) fun isActive(): Bool  // Check if within 48hrs
        access(all) fun markClaimed(user: Address)
    }
    
    access(all) struct Chapter5Status {
        access(all) let userAddress: Address
        access(all) var slackerComplete: Bool
        access(all) var overachieverComplete: Bool
        access(all) var nftAirdropped: Bool
        access(all) var nftID: UInt64?
        access(all) var completionTimestamp: UFix64
        
        init(userAddress: Address)
        
        access(all) fun updateSlacker()
        access(all) fun updateOverachiever()
        access(all) fun markNFTAirdropped(nftID: UInt64)
        access(all) fun isFullyComplete(): Bool
    }
    
    // RESOURCES
    access(all) resource UserProfile {
        access(all) var username: String
        access(all) var timezone: Int  // UTC offset (-12 to +14)
        access(all) let createdAt: UFix64
        
        init(username: String, timezone: Int)
        
        access(all) fun getLocalHour(): Int
        access(all) fun isDaytime(): Bool  // 6 AM - 6 PM = true
        access(all) fun updateTimezone(newTimezone: Int)
    }
    
    access(all) resource Chapter5NFT: NonFungibleToken.NFT {
        access(all) let id: UInt64
        access(all) let achievementType: String  // "SLACKER_AND_OVERACHIEVER"
        access(all) let recipient: Address
        access(all) let mintedAt: UFix64
        access(all) let metadata: {String: String}
        
        init(id: UInt64, recipient: Address)
    }
    
    access(all) resource Chapter5Collection: NonFungibleToken.Collection {
        access(all) var ownedNFTs: @{UInt64: {NonFungibleToken.NFT}}
        
        // Standard NFT collection functions
    }
    
    access(all) resource Admin {
        // GUM DROP FUNCTIONS
        access(all) fun createGumDrop(dropId: String, eligibleAddresses: [Address], amount: UFix64, durationSeconds: UFix64)
        access(all) fun markGumClaimed(user: Address)
        access(all) fun closeGumDrop()
        
        // CHAPTER 5 FUNCTIONS
        access(all) fun registerSlackerCompletion(userAddress: Address)
        access(all) fun registerOverachieverCompletion(userAddress: Address)
        access(all) fun airdropChapter5NFT(userAddress: Address)
    }
    
    // PUBLIC FUNCTIONS
    access(all) fun createUserProfile(username: String, timezone: Int): @UserProfile
    access(all) fun createEmptyChapter5Collection(): @Chapter5Collection
    
    // QUERY FUNCTIONS
    access(all) fun isEligibleForGumDrop(user: Address): Bool
    access(all) fun hasClaimedGumDrop(user: Address): Bool
    access(all) fun getGumDropInfo(): {String: AnyStruct}?
    access(all) fun getUserDayNightStatus(user: Address): {String: AnyStruct}
    access(all) fun getChapter5Status(user: Address): Chapter5Status?
    access(all) fun isEligibleForChapter5NFT(user: Address): Bool
}
```

---

## 🎃 GUM Drop vs Halloween - What Changed?

| Feature | Halloween (Before) | GumDrop (Now) |
|---------|-------------------|---------------|
| Window | 7 days | 48 hours |
| Use case | One-time event | Reusable system |
| Contract var | `halloweenDrop` | `activeGumDrop` |
| Function names | `createHalloweenDrop()` | `createGumDrop()` |
| Can run multiple? | No (single event) | Yes (close and reopen) |

**Same core logic, just more flexible!**

---

## 🌍 Day/Night - What's Different from flunks-site?

| Feature | flunks-site (Version A) | This Version (B) |
|---------|------------------------|------------------|
| Timezone | Central Time (hardcoded) | Per-user (stored) |
| Calculation | Global for everyone | Per user query |
| Trigger | Scheduled action hourly | On-demand query |
| Users see | Same image at same time | Different based on location |
| Image storage | Google Cloud buckets | Google Cloud (same) |

**Key:** No more `executeDayNightCycle()` scheduled action. Just query per user!

---

## 🏆 Chapter 5 NFTs - What's Different?

| Feature | flunks-site (Version A) | This Version (Combined) |
|---------|------------------------|-------------------------|
| Collection name | Chapter5NFTCollection | SemesterZero Collection |
| Storage path | Chapter5NFTCollectionStoragePath | Chapter5CollectionStoragePath |
| NFT type | Chapter 5 specific | Can add more types later |
| Tracking | ✅ Same (Chapter5Status) | ✅ Same |
| Airdrop logic | ✅ Same | ✅ Same |

**Basically the same, just renamed for clarity!**

---

## 🚀 Next Steps

1. **Merge the contracts** - Combine best of both versions
2. **Remove complexity** - No GumAccount, no transfers, no Flow Actions
3. **Test 3 features:**
   - Gum drop 48-hour claim
   - Per-user day/night
   - Chapter 5 NFT airdrop
4. **Deploy to testnet** by Oct 25
5. **Launch on Halloween** Oct 31

Want me to create the merged contract now? 🎯
