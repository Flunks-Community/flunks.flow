# SemesterZero Transactions & Scripts - Simplified

**Date**: October 20, 2025  
**Strategy**: Integrate with existing Supabase workflow

---

## 🎯 What We Actually Need

### **USER DOESN'T RUN TRANSACTIONS**
The website backend automatically handles everything!

### **Only 3 Transaction Types:**

1. **Setup Transactions** (User runs once)
   - `setup-user-profile.cdc` - Create profile with timezone
   - `setup-chapter5-collection.cdc` - Initialize NFT collection

2. **Admin Transactions** (Backend API runs)
   - `create-gum-drop.cdc` - Admin creates 48hr drop
   - `mark-gum-claimed.cdc` - Backend marks user claimed (after Supabase update)
   - `register-completion.cdc` - Backend registers slacker/overachiever (when Supabase detects completion)
   - `airdrop-nft.cdc` - Backend airdrops NFT (when both objectives complete)

3. **Query Scripts** (Website reads)
   - `check-gum-eligibility.cdc` - Check if user can claim
   - `check-day-night-status.cdc` - Get user's day/night image
   - `check-chapter5-status.cdc` - Get completion status

---

## 🔄 How Your Current System Works

### **Slacker Objective (Room 7 Key)**

```typescript
// weeklyObjectives.ts (EXISTING CODE)

async function checkRoom7KeyObjective(walletAddress: string) {
  // 1. Check Supabase
  const { data } = await supabase
    .from('paradise_motel_room7_keys')
    .select('obtained')
    .eq('wallet_address', walletAddress)
    .single();
  
  if (data?.obtained) {
    // 2. Update myLocker UI (green checkmark) ✅
    
    // 3. 🆕 CALL BACKEND TO REGISTER ON BLOCKCHAIN
    await fetch('/api/chapter5/register-slacker', {
      method: 'POST',
      body: JSON.stringify({ walletAddress })
    });
  }
}
```

### **Backend API (NEW)**

```typescript
// app/api/chapter5/register-slacker/route.ts

import * as fcl from '@onflow/fcl';

export async function POST(req: Request) {
  const { walletAddress } = await req.json();
  
  // Verify in Supabase first
  const { data } = await supabase
    .from('paradise_motel_room7_keys')
    .select('obtained')
    .eq('wallet_address', walletAddress)
    .single();
  
  if (!data?.obtained) {
    return Response.json({ error: 'Not completed' }, { status: 400 });
  }
  
  // Register on blockchain
  const txId = await fcl.mutate({
    cadence: REGISTER_SLACKER_TRANSACTION,
    args: (arg, t) => [arg(walletAddress, t.Address)],
    authorizations: [adminAuthz] // Backend signs as admin
  });
  
  // Log to Supabase
  await supabase.from('chapter5_blockchain_sync').insert({
    wallet_address: walletAddress,
    objective: 'slacker',
    tx_id: txId,
    synced_at: new Date().toISOString()
  });
  
  return Response.json({ success: true, txId });
}
```

---

## 🎯 Simplified Flow

### **1. Setup (User Runs Once)**

```
User Signs Up
    ↓
Wallet Connect
    ↓
Run: setup-user-profile.cdc (creates UserProfile with timezone)
    ↓
Run: setup-chapter5-collection.cdc (creates NFT collection)
    ↓
Ready! ✅
```

### **2. Slacker Objective (Automated)**

```
User completes maid dialogue at Paradise Motel
    ↓
Game stores: paradise_motel_room7_keys.obtained = true
    ↓
weeklyObjectives.ts detects completion
    ↓
Shows green checkmark in myLocker ✅
    ↓
Calls: POST /api/chapter5/register-slacker
    ↓
Backend verifies in Supabase
    ↓
Backend runs: register-completion.cdc (blockchain)
    ↓
Blockchain marks: slackerComplete = true
    ↓
Done! 🎉
```

### **3. Overachiever Objective (Same Pattern)**

```
User completes overachiever task (wire it up on website)
    ↓
Supabase: overachiever_task.completed = true
    ↓
Backend detects completion
    ↓
Calls: POST /api/chapter5/register-overachiever
    ↓
Backend runs: register-completion.cdc (blockchain)
    ↓
Blockchain marks: overachieverComplete = true
    ↓
Done! 🎉
```

### **4. NFT Airdrop (Fully Automated)**

```
Both objectives complete
    ↓
Blockchain emits: Chapter5FullCompletion event
    ↓
Backend listens for event OR checks periodically
    ↓
Backend runs: airdrop-nft.cdc
    ↓
NFT minted and sent to user's wallet
    ↓
User sees NFT in myLocker + Flow wallet 🏆
```

---

## 📝 Transactions We Actually Need

### **1. Setup Transactions (User Runs)**

```cadence
// setup-user-profile.cdc
// Run once when user signs up

transaction(username: String, timezone: Int) {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Create profile
        let profile <- SemesterZero.createUserProfile(
            username: username,
            timezone: timezone
        )
        
        // Save to storage
        signer.storage.save(<-profile, to: SemesterZero.UserProfileStoragePath)
        
        // Link public capability
        let cap = signer.capabilities.storage.issue<&SemesterZero.UserProfile>(
            SemesterZero.UserProfileStoragePath
        )
        signer.capabilities.publish(cap, at: SemesterZero.UserProfilePublicPath)
    }
}
```

```cadence
// setup-chapter5-collection.cdc
// Run once when user wants to receive NFTs

transaction {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Create collection
        let collection <- SemesterZero.createEmptyChapter5Collection()
        
        // Save to storage
        signer.storage.save(<-collection, to: SemesterZero.Chapter5CollectionStoragePath)
        
        // Link public capability
        let cap = signer.capabilities.storage.issue<&{NonFungibleToken.Receiver}>(
            SemesterZero.Chapter5CollectionStoragePath
        )
        signer.capabilities.publish(cap, at: SemesterZero.Chapter5CollectionPublicPath)
    }
}
```

---

### **2. Backend Transactions (API Runs)**

```cadence
// register-completion.cdc
// Backend calls when Supabase detects completion

transaction(userAddress: Address, objectiveType: String) {
    let adminRef: &SemesterZero.Admin
    
    prepare(admin: auth(Storage) &Account) {
        self.adminRef = admin.storage.borrow<&SemesterZero.Admin>(
            from: SemesterZero.AdminStoragePath
        ) ?? panic("No admin resource")
    }
    
    execute {
        if objectiveType == "slacker" {
            self.adminRef.registerSlackerCompletion(userAddress: userAddress)
        } else if objectiveType == "overachiever" {
            self.adminRef.registerOverachieverCompletion(userAddress: userAddress)
        } else {
            panic("Invalid objective type")
        }
    }
}
```

```cadence
// airdrop-nft.cdc
// Backend calls when both objectives complete

transaction(userAddress: Address) {
    let adminRef: &SemesterZero.Admin
    
    prepare(admin: auth(Storage) &Account) {
        self.adminRef = admin.storage.borrow<&SemesterZero.Admin>(
            from: SemesterZero.AdminStoragePath
        ) ?? panic("No admin resource")
    }
    
    execute {
        self.adminRef.airdropChapter5NFT(userAddress: userAddress)
    }
}
```

---

### **3. Query Scripts (Website Reads)**

```cadence
// check-chapter5-status.cdc
// Check user's completion status

import SemesterZero from "../contracts/SemesterZero_Hackathon.cdc"

access(all) fun main(userAddress: Address): {String: AnyStruct}? {
    let status = SemesterZero.getChapter5Status(userAddress: userAddress)
    
    if status == nil {
        return nil
    }
    
    return {
        "slackerComplete": status!.slackerComplete,
        "overachieverComplete": status!.overachieverComplete,
        "isFullyComplete": status!.isFullyComplete(),
        "nftAirdropped": status!.nftAirdropped,
        "nftID": status!.nftID,
        "completionTimestamp": status!.completionTimestamp
    }
}
```

```cadence
// check-day-night-status.cdc
// Get user's day/night image URL

import SemesterZero from "../contracts/SemesterZero_Hackathon.cdc"

access(all) fun main(userAddress: Address): {String: AnyStruct} {
    return SemesterZero.getUserDayNightStatus(userAddress: userAddress)
}
```

---

## 🆕 What You Need to Add to Website

### **1. Backend API Routes**

```
/api/chapter5/register-slacker
/api/chapter5/register-overachiever
/api/chapter5/check-and-airdrop  (checks if both done, then airdrops)
```

### **2. Update weeklyObjectives.ts**

```typescript
// EXISTING: Check Supabase
const hasKey = await checkRoom7KeyObjective(walletAddress);

// ADD: Sync to blockchain
if (hasKey) {
  await syncSlackerToBlockchain(walletAddress);
}

async function syncSlackerToBlockchain(walletAddress: string) {
  // Call backend API
  await fetch('/api/chapter5/register-slacker', {
    method: 'POST',
    body: JSON.stringify({ walletAddress })
  });
}
```

### **3. Periodic Check for NFT Airdrop**

```typescript
// Backend cron job (runs every hour)
// app/api/cron/check-chapter5-airdrops/route.ts

export async function GET(req: Request) {
  // Get users who completed both but haven't received NFT
  const { data: users } = await supabase
    .from('chapter5_status_view')
    .select('wallet_address')
    .eq('slacker_complete', true)
    .eq('overachiever_complete', true)
    .eq('nft_airdropped', false);
  
  for (const user of users) {
    // Check blockchain status
    const status = await fcl.query({
      cadence: CHECK_CHAPTER5_STATUS_SCRIPT,
      args: (arg, t) => [arg(user.wallet_address, t.Address)]
    });
    
    if (status?.isFullyComplete && !status?.nftAirdropped) {
      // Airdrop NFT!
      await fcl.mutate({
        cadence: AIRDROP_NFT_TRANSACTION,
        args: (arg, t) => [arg(user.wallet_address, t.Address)],
        authorizations: [adminAuthz]
      });
    }
  }
}
```

---

## ✅ Summary

### **User Transactions (Run Once):**
1. Setup profile with timezone
2. Setup NFT collection

### **Backend Handles Everything Else:**
- Supabase detects completion (Room 7 key, overachiever task)
- Backend API syncs to blockchain
- Backend API airdrops NFT when both complete

### **No Manual Registration Needed:**
- User doesn't run separate "register slacker" transaction
- User doesn't run separate "register overachiever" transaction
- Backend automatically handles it when Supabase detects completion

**This matches your current workflow! 🎯**

Want me to create just these simplified transactions and scripts now?
