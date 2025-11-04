# System Architecture Summary

**Date**: October 20, 2025  
**All features integrated into SemesterZero.cdc** ✅

---

## 🎯 Question 1: Is Halloween in SemesterZero.cdc?

### **YES! ✅ It's all in SemesterZero.cdc**

**Location**: `cadence/contracts/SemesterZero.cdc`

**What was added:**
- Lines 52-53: Halloween events
- Lines 877-917: Admin functions (createHalloweenDrop, markHalloweenClaimed, clearHalloweenDrop)
- Lines 1239-1275: HalloweenDrop struct
- Lines 1279-1310: Halloween eligibility functions

**No separate contract needed!** Everything is baked into SemesterZero.cdc.

```cadence
// In SemesterZero.cdc:

// 1. Events
access(all) event HalloweenDropCreated(...)
access(all) event HalloweenClaimed(...)

// 2. Data structure
access(all) struct HalloweenDrop {
    // Tracks who is eligible and who claimed
}

// 3. State
access(all) var halloweenDrop: HalloweenDrop?

// 4. Public functions
access(all) fun isEligibleForHalloween(_ user: Address): Bool
access(all) fun hasClaimedHalloween(_ user: Address): Bool
access(all) fun getHalloweenDropInfo(): {String: AnyStruct}?

// 5. Admin functions (in Admin resource)
access(all) fun createHalloweenDrop(...)
access(all) fun markHalloweenClaimed(...)
```

---

## 🎯 Question 2: Day/Night System - 12 Hour Cycle Based on User Location?

### **YES! ✅ It's based on each user's timezone**

**How it works:**

### **1. User Profile Stores Timezone**
```cadence
// In SemesterZero.cdc - UserProfile resource (lines 69-122)

access(all) resource UserProfile {
    access(all) var timezone: Int  // Hours offset from UTC (-12 to +14)
    
    // Calculate user's local hour
    access(all) fun getLocalHour(): Int {
        let timestamp = getCurrentBlock().timestamp  // UTC time
        let utcHour = Int((timestamp / 3600) % 24)
        var localHour = utcHour + self.timezone  // Add timezone offset
        
        // Wrap around (0-23)
        if localHour < 0 {
            localHour = localHour + 24
        } else if localHour >= 24 {
            localHour = localHour - 24
        }
        
        return localHour
    }
    
    // Check if it's daytime (6 AM - 6 PM)
    access(all) fun isDaytime(): Bool {
        let hour = self.getLocalHour()
        return hour >= 6 && hour < 18  // 6 AM to 6 PM = day
    }
}
```

### **2. 12-Hour Cycles**

**Daytime**: 6 AM - 6 PM (12 hours) → Day image  
**Nighttime**: 6 PM - 6 AM (12 hours) → Night image

### **3. Based on Each User's Location**

**Example:**

```
User A in New York (UTC-5):
- Blockchain time: 3:00 PM UTC
- Local time: 10:00 AM EST (3 PM - 5 hours)
- Hour: 10 (between 6 and 18)
- Result: Daytime ✅ (shows day image)

User B in Tokyo (UTC+9):
- Blockchain time: 3:00 PM UTC
- Local time: 12:00 AM JST (3 PM + 9 hours)
- Hour: 0 (not between 6 and 18)
- Result: Nighttime 🌙 (shows night image)

User C in London (UTC+0):
- Blockchain time: 3:00 PM UTC
- Local time: 3:00 PM GMT
- Hour: 15 (between 6 and 18)
- Result: Daytime ✅ (shows day image)
```

**SAME MOMENT, DIFFERENT IMAGES based on user location!**

---

## 🏗️ Architecture Overview

### **All in ONE Contract: SemesterZero.cdc**

```
SemesterZero.cdc
├── UserProfile (with timezone tracking)
│   ├── timezone: Int
│   ├── getLocalHour() → calculates local time
│   └── isDaytime() → true if 6 AM - 6 PM
│
├── GumAccount (reward tracking)
│   ├── balance: UFix64
│   ├── deposit()
│   └── transfer()
│
├── HalloweenDrop (claim eligibility)
│   ├── eligibleUsers: {Address: Bool}
│   ├── claimedUsers: {Address: UFix64}
│   ├── isEligible()
│   └── markClaimed()
│
├── Admin (management functions)
│   ├── createHalloweenDrop()
│   ├── markHalloweenClaimed()
│   └── syncUserBalance()
│
└── VirtualGumVault (Flow Actions marker)
    └── For future automation
```

---

## 📊 ParadiseMotel.cdc - Helper Contract

**Purpose**: Helper functions for Paradise Motel day/night images  
**Does NOT store NFTs** - just resolves which image to show

```cadence
// ParadiseMotel.cdc imports SemesterZero

access(all) contract ParadiseMotel {
    
    // Resolve which image to show
    access(all) fun resolveParadiseMotelImage(
        ownerAddress: Address,
        dayImageURI: String,
        nightImageURI: String
    ): String {
        // Get user's profile from SemesterZero
        let profile = getAccount(ownerAddress)
            .capabilities.get<&SemesterZero.UserProfile>(...)
            .borrow()
        
        // Check if it's daytime for this user
        let isDaytime = profile.isDaytime()
        
        // Return appropriate image
        return isDaytime ? dayImageURI : nightImageURI
    }
    
    // Batch check for multiple users
    access(all) fun batchGetTimeContext(addresses: [Address]): [{String: AnyStruct}]
}
```

**ParadiseMotel is optional** - you could do all this in SemesterZero too, but we separated it for clarity.

---

## 🔄 How Paradise Motel Works for Different Users

### **Scenario: 3 Users Check at Same Time (3:00 PM UTC)**

```
┌─────────────────────────────────────────────────────────────┐
│  User A (New York, UTC-5)                                   │
│  Local Time: 10:00 AM                                       │
│  Hour: 10                                                   │
│  isDaytime(): 10 >= 6 && 10 < 18 = TRUE                   │
│  Result: Day image (paradise-motel-day.png) ☀️            │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  User B (Tokyo, UTC+9)                                      │
│  Local Time: 12:00 AM (midnight)                           │
│  Hour: 0                                                    │
│  isDaytime(): 0 >= 6 && 0 < 18 = FALSE                    │
│  Result: Night image (paradise-motel-night.png) 🌙        │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  User C (London, UTC+0)                                     │
│  Local Time: 3:00 PM                                        │
│  Hour: 15                                                   │
│  isDaytime(): 15 >= 6 && 15 < 18 = TRUE                   │
│  Result: Day image (paradise-motel-day.png) ☀️            │
└─────────────────────────────────────────────────────────────┘
```

**Each user sees a different image at the same moment!**

---

## 🎯 Key Points

### **Halloween System:**
✅ **All in SemesterZero.cdc** (no separate contract)  
✅ **Tracks eligibility + claims** on blockchain  
✅ **GUM lives in Supabase** (blockchain just marks who can/did claim)  
✅ **One contract to deploy**

### **Day/Night System:**
✅ **Based on each user's timezone** (stored in UserProfile)  
✅ **12-hour cycles**: 6 AM - 6 PM = day, 6 PM - 6 AM = night  
✅ **Calculated dynamically** every time you check  
✅ **Different users see different images** at the same moment  
✅ **Helper contract (ParadiseMotel.cdc)** for convenience, but uses SemesterZero.UserProfile

---

## 📁 File Structure

```
cadence/contracts/
├── SemesterZero.cdc          ← MAIN CONTRACT (has everything!)
│   ├── UserProfile (timezone, isDaytime())
│   ├── GumAccount (GUM tracking)
│   ├── HalloweenDrop (claim eligibility)
│   └── Admin (all management)
│
└── ParadiseMotel.cdc         ← HELPER (optional, uses SemesterZero)
    └── Convenience functions for image resolution
```

---

## 🚀 Deployment

**You only need to deploy/update ONE main contract:**

```bash
# Update SemesterZero with Halloween + existing timezone features
flow accounts update-contract SemesterZero \
  cadence/contracts/SemesterZero.cdc \
  --network testnet \
  --signer admin

# Optional: Deploy helper contract
flow accounts add-contract ParadiseMotel \
  cadence/contracts/ParadiseMotel.cdc \
  --network testnet \
  --signer admin
```

**SemesterZero.cdc has:**
- ✅ Halloween claim system
- ✅ Timezone tracking
- ✅ Day/night calculation (isDaytime())
- ✅ GUM accounts
- ✅ All admin functions

**Everything in one place!** 🎉
