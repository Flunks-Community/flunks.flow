# Halloween Airdrop: Claim System (Supabase Only)

**Date**: October 20, 2025  
**Correct Approach**: Blockchain triggers eligibility, user claims to Supabase

---

## 🎯 What You Actually Want

```
Halloween Night (Oct 31)
    ↓
Blockchain marks users as "eligible"
    ↓
User visits website
    ↓
Website checks: "Is this user eligible?"
    ↓
Shows popup: "🎃 Claim Your 100 Halloween GUM!"
    ↓
User clicks "Claim"
    ↓
Supabase: user_gum_balances += 100
    ↓
Blockchain marks: "claimed = true"
    ↓
GUM stays in Supabase (just like daily clicking!)
```

**Blockchain = Eligibility tracker only**  
**Supabase = Where GUM actually lives**

---

## 🏗️ Architecture

### **On Blockchain (SemesterZero.cdc):**
```cadence
// Just tracks WHO is eligible and WHO claimed
access(all) struct HalloweenDrop {
    access(all) let dropId: String          // "halloween_2025"
    access(all) let amount: UFix64           // 100.0
    access(all) let eligibleUsers: {Address: Bool}  // Who can claim
    access(all) var claimedUsers: {Address: UFix64} // Who did claim (timestamp)
}
```

**No GUM transferred on blockchain!**  
Just a list of who's eligible + who claimed.

---

### **On Supabase:**
```sql
-- User GUM balances (unchanged)
CREATE TABLE user_gum_balances (
    wallet_address TEXT PRIMARY KEY,
    total_gum NUMERIC DEFAULT 0,  -- All GUM lives here!
    last_updated TIMESTAMP DEFAULT NOW()
);

-- Halloween eligibility (synced from blockchain)
CREATE TABLE halloween_eligibility (
    wallet_address TEXT PRIMARY KEY,
    eligible BOOLEAN DEFAULT FALSE,
    claimed BOOLEAN DEFAULT FALSE,
    amount NUMERIC DEFAULT 100,
    eligible_at TIMESTAMP,
    claimed_at TIMESTAMP
);
```

---

## 🔄 Complete Flow

### **Step 1: October 31 - Mark Eligible Users (Blockchain)**

```typescript
// app/api/halloween/mark-eligible/route.ts
export async function POST(req: Request) {
  // Triggered by Vercel Cron at midnight Oct 31
  
  // Query Supabase for users who earned 50+ GUM
  const { data: eligibleUsers } = await supabase
    .from('user_gum_balances')
    .select('wallet_address')
    .gte('total_gum', 50);
  
  // Send ONE blockchain transaction to mark all eligible
  const txId = await fcl.mutate({
    cadence: `
      import SemesterZero from 0xSemesterZero
      
      transaction(addresses: [Address]) {
        prepare(admin: &Account) {
          let adminRef = admin.storage.borrow<&SemesterZero.Admin>(
            from: SemesterZero.AdminStoragePath
          ) ?? panic("No admin resource")
          
          // Mark all users as eligible (no GUM transferred!)
          adminRef.createHalloweenDrop(
            dropId: "halloween_2025",
            eligibleAddresses: addresses,
            amount: 100.0
          )
        }
      }
    `,
    args: (arg, t) => [
      arg(eligibleUsers.map(u => u.wallet_address), t.Array(t.Address))
    ]
  });
  
  // Sync to Supabase for faster querying
  for (const user of eligibleUsers) {
    await supabase.from('halloween_eligibility').insert({
      wallet_address: user.wallet_address,
      eligible: true,
      amount: 100,
      eligible_at: new Date().toISOString()
    });
  }
  
  return Response.json({ success: true, eligible: eligibleUsers.length });
}
```

---

### **Step 2: User Visits Website (Shows Claim Button)**

```typescript
// app/components/HalloweenClaimPopup.tsx
'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/contexts/AuthContext';

export default function HalloweenClaimPopup() {
  const { user } = useAuth();
  const [isEligible, setIsEligible] = useState(false);
  const [hasClaimed, setHasClaimed] = useState(false);
  const [loading, setLoading] = useState(false);
  
  useEffect(() => {
    checkEligibility();
  }, [user]);
  
  async function checkEligibility() {
    if (!user?.addr) return;
    
    // Fast check: Query Supabase first
    const { data } = await supabase
      .from('halloween_eligibility')
      .select('eligible, claimed')
      .eq('wallet_address', user.addr)
      .single();
    
    if (data) {
      setIsEligible(data.eligible);
      setHasClaimed(data.claimed);
    } else {
      // Fallback: Query blockchain if not in Supabase yet
      const result = await fcl.query({
        cadence: `
          import SemesterZero from 0xSemesterZero
          
          access(all) fun main(userAddress: Address): Bool {
            return SemesterZero.isEligibleForHalloween(userAddress)
          }
        `,
        args: (arg, t) => [arg(user.addr, t.Address)]
      });
      
      setIsEligible(result);
    }
  }
  
  async function claimHalloweenGum() {
    setLoading(true);
    
    try {
      // Call API to claim
      const res = await fetch('/api/halloween/claim', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ walletAddress: user.addr })
      });
      
      const data = await res.json();
      
      if (data.success) {
        setHasClaimed(true);
        // Show success message
        alert(`🎃 Claimed 100 Halloween GUM! New balance: ${data.newBalance}`);
      }
    } catch (error) {
      console.error('Claim failed:', error);
    } finally {
      setLoading(false);
    }
  }
  
  // Don't show if not eligible or already claimed
  if (!isEligible || hasClaimed) return null;
  
  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-8 max-w-md">
        <div className="text-6xl text-center mb-4">🎃</div>
        <h2 className="text-2xl font-bold text-center mb-2">
          Halloween Special Drop!
        </h2>
        <p className="text-center text-gray-600 mb-6">
          You've earned <strong>100 GUM</strong> for being an active Flunks member!
        </p>
        
        <button
          onClick={claimHalloweenGum}
          disabled={loading}
          className="w-full bg-orange-500 hover:bg-orange-600 text-white font-bold py-3 px-6 rounded-lg"
        >
          {loading ? 'Claiming...' : 'Claim 100 GUM 🎃'}
        </button>
        
        <p className="text-xs text-gray-500 text-center mt-4">
          Available until November 7, 2025
        </p>
      </div>
    </div>
  );
}
```

---

### **Step 3: User Clicks "Claim" (GUM Added to Supabase)**

```typescript
// app/api/halloween/claim/route.ts
import { createClient } from '@supabase/supabase-js';
import * as fcl from '@onflow/fcl';

export async function POST(req: Request) {
  const { walletAddress } = await req.json();
  
  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
  );
  
  // Step 1: Verify user is eligible and hasn't claimed
  const { data: eligibility } = await supabase
    .from('halloween_eligibility')
    .select('eligible, claimed, amount')
    .eq('wallet_address', walletAddress)
    .single();
  
  if (!eligibility?.eligible) {
    return Response.json({ error: 'Not eligible' }, { status: 403 });
  }
  
  if (eligibility.claimed) {
    return Response.json({ error: 'Already claimed' }, { status: 409 });
  }
  
  // Step 2: Add GUM to Supabase (just like daily clicking!)
  const { data: updatedBalance } = await supabase
    .from('user_gum_balances')
    .update({ 
      total_gum: supabase.raw(`total_gum + ${eligibility.amount}`)
    })
    .eq('wallet_address', walletAddress)
    .select('total_gum')
    .single();
  
  // Step 3: Mark as claimed in Supabase
  await supabase
    .from('halloween_eligibility')
    .update({ 
      claimed: true,
      claimed_at: new Date().toISOString()
    })
    .eq('wallet_address', walletAddress);
  
  // Step 4: Mark as claimed on blockchain (optional, for permanent record)
  try {
    await fcl.mutate({
      cadence: `
        import SemesterZero from 0xSemesterZero
        
        transaction(userAddress: Address) {
          prepare(admin: &Account) {
            let adminRef = admin.storage.borrow<&SemesterZero.Admin>(
              from: SemesterZero.AdminStoragePath
            ) ?? panic("No admin resource")
            
            // Just mark as claimed (no GUM transferred!)
            adminRef.markHalloweenClaimed(userAddress)
          }
        }
      `,
      args: (arg, t) => [arg(walletAddress, t.Address)],
      authorizations: [fcl.authz] // Admin authorization
    });
  } catch (error) {
    console.error('Blockchain update failed (non-critical):', error);
    // Continue anyway - Supabase is source of truth
  }
  
  return Response.json({ 
    success: true, 
    newBalance: updatedBalance.total_gum,
    claimed: eligibility.amount
  });
}
```

---

## 🎯 Key Changes to SemesterZero.cdc

Add this to the contract:

```cadence
// In SemesterZero contract
access(all) struct HalloweenDrop {
    access(all) let dropId: String
    access(all) let amount: UFix64
    access(all) let startTime: UFix64
    access(all) let endTime: UFix64
    access(all) let eligibleUsers: {Address: Bool}
    access(all) var claimedUsers: {Address: UFix64}
    
    init(dropId: String, amount: UFix64, eligibleUsers: [Address]) {
        self.dropId = dropId
        self.amount = amount
        self.startTime = getCurrentBlock().timestamp
        self.endTime = self.startTime + 604800.0 // 7 days
        self.eligibleUsers = {}
        self.claimedUsers = {}
        
        for addr in eligibleUsers {
            self.eligibleUsers[addr] = true
        }
    }
    
    access(all) fun markClaimed(user: Address) {
        pre {
            self.eligibleUsers[user] == true: "User not eligible"
            self.claimedUsers[user] == nil: "Already claimed"
        }
        self.claimedUsers[user] = getCurrentBlock().timestamp
    }
}

// Store active drops
access(all) var halloweenDrop: HalloweenDrop?

// Check if user is eligible
access(all) fun isEligibleForHalloween(_ user: Address): Bool {
    if let drop = SemesterZero.halloweenDrop {
        return drop.eligibleUsers[user] == true && drop.claimedUsers[user] == nil
    }
    return false
}

// Check if user already claimed
access(all) fun hasClaimedHalloween(_ user: Address): Bool {
    if let drop = SemesterZero.halloweenDrop {
        return drop.claimedUsers[user] != nil
    }
    return false
}

// Admin functions
access(all) resource Admin {
    // ... existing functions ...
    
    access(all) fun createHalloweenDrop(
        dropId: String, 
        eligibleAddresses: [Address],
        amount: UFix64
    ) {
        SemesterZero.halloweenDrop = HalloweenDrop(
            dropId: dropId,
            amount: amount,
            eligibleUsers: eligibleAddresses
        )
        
        emit HalloweenDropCreated(
            dropId: dropId,
            eligibleCount: eligibleAddresses.length,
            amount: amount
        )
    }
    
    access(all) fun markHalloweenClaimed(_ user: Address) {
        if let drop = SemesterZero.halloweenDrop {
            drop.markClaimed(user: user)
            
            emit HalloweenClaimed(
                user: user,
                amount: drop.amount,
                timestamp: getCurrentBlock().timestamp
            )
        }
    }
}

// Events
access(all) event HalloweenDropCreated(dropId: String, eligibleCount: Int, amount: UFix64)
access(all) event HalloweenClaimed(user: Address, amount: UFix64, timestamp: UFix64)
```

---

## 📊 Data Flow Comparison

### **OLD Approach (What I thought you wanted):**
```
Blockchain stores GUM ❌
    ↓
User has two balances (Supabase + Blockchain) ❌
    ↓
Need to sync constantly ❌
```

### **NEW Approach (What you actually want):**
```
Blockchain = Eligibility list ✅
    ↓
User clicks "Claim" ✅
    ↓
Supabase stores GUM (just like daily) ✅
    ↓
Blockchain marks "claimed = true" ✅
    ↓
NO SYNCING NEEDED ✅
```

---

## 🎃 Complete User Experience

### **October 31, 12:00 AM:**
- Cron job runs
- Blockchain: Marks 1000 users as eligible
- Supabase: Syncs eligibility list
- **GUM not added yet!**

### **November 1, User logs in:**
```
┌─────────────────────────────────────┐
│  🎃 Halloween Special Drop!         │
├─────────────────────────────────────┤
│                                     │
│  You've earned 100 GUM for being   │
│  an active Flunks member!           │
│                                     │
│  [Claim 100 GUM 🎃]                 │
│                                     │
│  Available until Nov 7, 2025        │
└─────────────────────────────────────┘
```

### **User clicks "Claim":**
- API checks eligibility ✅
- Supabase: `total_gum += 100` ✅
- Blockchain: Marks claimed ✅
- Popup closes ✅
- Balance updates ✅

### **User sees updated balance:**
```
Before: 515 GUM
After:  615 GUM

(Just like daily clicking - all in Supabase!)
```

---

## 💰 Cost Analysis

### **Blockchain Transactions:**
1. **Mark all eligible** (Oct 31): 1 transaction = $0.00007
2. **Mark claimed** (per user): 1000 users × $0.00007 = $0.07

**Total: ~$0.07 for 1000 users**

### **Why This is Cheaper:**
- Only ONE transaction to mark everyone eligible
- Claiming transactions are optional (can skip if you want)
- GUM never moves on-chain (no deposit transactions!)

---

## ✅ Benefits of This Approach

1. **All GUM stays in Supabase**
   - Just like your current system
   - No separate blockchain GUM
   - No syncing issues

2. **Blockchain = Proof of Eligibility**
   - Permanent record of who was eligible
   - Can't be faked or manipulated
   - Transparent and verifiable

3. **Fast User Experience**
   - Check eligibility: < 100ms (Supabase)
   - Click claim: < 100ms (Supabase update)
   - Mark claimed: Async (doesn't slow down UI)

4. **No Breaking Changes**
   - Daily clicking unchanged
   - GUM all in one place (Supabase)
   - Just adds claim popup for eligible users

---

## 🚀 Implementation Checklist

- [ ] Add `HalloweenDrop` struct to SemesterZero.cdc
- [ ] Add eligibility functions (isEligible, hasClaimed)
- [ ] Add Admin functions (createDrop, markClaimed)
- [ ] Create `halloween_eligibility` table in Supabase
- [ ] Create `/api/halloween/mark-eligible` endpoint
- [ ] Create `/api/halloween/claim` endpoint
- [ ] Create `HalloweenClaimPopup` component
- [ ] Set up Vercel Cron for Oct 31
- [ ] Test on testnet

---

## 📝 Summary

**Blockchain Role**: Eligibility tracker (who can claim)  
**Supabase Role**: GUM storage (where GUM lives)  
**User Experience**: Click "Claim" → GUM added to Supabase (instant)

**This matches your current system perfectly!**  
Halloween is just a special claim button that shows up for eligible users.  
All GUM stays in Supabase. No separate balances. No syncing.

🎃 **Much simpler!**
