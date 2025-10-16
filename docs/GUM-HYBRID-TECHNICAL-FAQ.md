# GUM Hybrid System - Technical Deep Dive

## 🔍 Your Questions Answered

### 1. ✅ NFT Gating - How Does It Work?

**Yes, it directly checks Flunks.cdc on-chain!** No database lookup needed.

#### How It Works:

```cadence
// In the transaction (claim-special-drop.cdc):
transaction(dropID: UInt64) {
    let flunksCollection: &{NonFungibleToken.CollectionPublic}?
    
    prepare(signer: auth(Storage, BorrowValue) &Account) {
        // Try to borrow user's Flunks collection
        self.flunksCollection = signer.capabilities.get<&{NonFungibleToken.CollectionPublic}>(
            Flunks.CollectionPublicPath  // ← References Flunks.cdc directly!
        ).borrow()
    }
    
    execute {
        // Pass collection to contract
        GumDropsHybrid.claimSpecialDrop(
            dropID: dropID,
            claimer: self.gumAccount,
            flunksCollection: self.flunksCollection  // ← Can be nil if user doesn't have collection
        )
    }
}
```

```cadence
// In the contract (GumDropsHybrid.cdc):
access(all) fun claimSpecialDrop(
    dropID: UInt64,
    claimer: &GumAccount,
    flunksCollection: &{NonFungibleToken.CollectionPublic}?  // ← Optional reference
) {
    let dropRef = &GumDropsHybrid.specialDrops[dropID] as &SpecialDrop?
        ?? panic("Drop not found")
    
    // Check if user actually owns Flunks NFTs
    let hasFlunks = flunksCollection != nil && flunksCollection!.getIDs().length > 0
    //                                           ↑ Gets actual NFT IDs from Flunks contract!
    
    // Claim with verification
    let amount = dropRef.claim(claimer: claimer.owner!.address, hasFlunks: hasFlunks)
    // ...
}
```

```cadence
// Inside SpecialDrop resource:
access(contract) fun claim(claimer: Address, hasFlunks: Bool): UFix64 {
    pre {
        !self.requiresFlunks || hasFlunks: "Requires Flunks NFT ownership"
        //  ↑ If drop requires Flunks, user MUST have them!
    }
    // ...
}
```

**Summary:**
- ✅ Direct on-chain verification
- ✅ Checks actual Flunks.cdc contract
- ✅ Counts real NFT IDs (`.getIDs().length`)
- ✅ Can't be faked (blockchain verification)
- ✅ No database lookup needed

---

### 2. 📊 Leaderboard - Two Options!

You have **TWO ways** to build leaderboards:

#### **Option A: Blockchain-Only Leaderboard** (Trustless, verifiable)

Query all on-chain GUM balances from the blockchain:

```typescript
// website/lib/getGumLeaderboard.ts
import * as fcl from '@onflow/fcl';

// Script to get multiple users' balances
const GET_MULTIPLE_BALANCES = `
  import GumDropsHybrid from 0xYOUR_ADDRESS
  
  access(all) fun main(addresses: [Address]): {Address: UFix64} {
    let balances: {Address: UFix64} = {}
    
    for address in addresses {
      let account = getAccount(address)
      
      if let cap = account.capabilities.get<&GumDropsHybrid.GumAccount>(
        GumDropsHybrid.GumAccountPublicPath
      ) {
        if let gumAccount = cap.borrow() {
          let info = gumAccount.getInfo()
          balances[address] = info.balance
        }
      }
    }
    
    return balances
  }
`;

export async function getBlockchainGumLeaderboard(limit: number = 100) {
  // 1. Get all user addresses from Supabase (just addresses)
  const { data: users } = await supabase
    .from('user_gum_balances')
    .select('wallet_address')
    .limit(1000);
  
  const addresses = users.map(u => u.wallet_address);
  
  // 2. Query blockchain for REAL balances
  const balances = await fcl.query({
    cadence: GET_MULTIPLE_BALANCES,
    args: (arg, t) => [arg(addresses, t.Array(t.Address))]
  });
  
  // 3. Sort by on-chain balance
  const leaderboard = addresses
    .map(addr => ({
      address: addr,
      gum: balances[addr] || 0,
      verified: true  // ← On-chain verified!
    }))
    .sort((a, b) => b.gum - a.gum)
    .slice(0, limit);
  
  return leaderboard;
}
```

**Pros:**
- ✅ 100% trustless (can't fake)
- ✅ Verifiable on blockchain
- ✅ Public & transparent

**Cons:**
- ⏱️ Slower (blockchain queries)
- 💰 More RPC calls (rate limits)
- 🔄 Only shows synced balances

---

#### **Option B: Supabase Leaderboard** (Fast, includes unsynced)

Query Supabase for the latest balances:

```typescript
// website/lib/getGumLeaderboard.ts
export async function getSupabaseGumLeaderboard(limit: number = 100) {
  const { data } = await supabase
    .from('user_gum_balances')
    .select('wallet_address, total_gum, updated_at')
    .order('total_gum', { ascending: false })
    .limit(limit);
  
  return data.map(user => ({
    address: user.wallet_address,
    gum: user.total_gum,
    lastUpdated: user.updated_at,
    verified: false  // ← Not yet synced to blockchain
  }));
}
```

**Pros:**
- ⚡ Super fast (database query)
- 💰 Free (no RPC costs)
- 🔄 Shows latest earnings (even if not synced yet)

**Cons:**
- ⚠️ Could be manipulated (admin has DB access)
- ❌ Not verifiable on-chain
- 🔓 Requires trust in your backend

---

#### **Option C: Hybrid Leaderboard** (Best of both! 🏆)

Show Supabase data with blockchain verification badge:

```tsx
// components/GumLeaderboard.tsx
'use client';

import { useState, useEffect } from 'react';

export function GumLeaderboard() {
  const [leaders, setLeaders] = useState([]);
  
  useEffect(() => {
    async function loadLeaderboard() {
      // 1. Get Supabase leaderboard (fast)
      const supabaseLeaders = await getSupabaseGumLeaderboard(100);
      
      // 2. Get blockchain balances for top 10 (verification)
      const top10Addresses = supabaseLeaders.slice(0, 10).map(l => l.address);
      const blockchainBalances = await getBlockchainBalances(top10Addresses);
      
      // 3. Merge: Show Supabase balance + blockchain verification
      const mergedLeaders = supabaseLeaders.map(leader => {
        const onChainBalance = blockchainBalances[leader.address];
        
        return {
          ...leader,
          onChainBalance: onChainBalance || 0,
          verified: onChainBalance !== undefined && 
                    Math.abs(onChainBalance - leader.gum) < 1  // Allow 1 GUM difference
        };
      });
      
      setLeaders(mergedLeaders);
    }
    
    loadLeaderboard();
  }, []);
  
  return (
    <div className="leaderboard">
      <h2>🏆 GUM Leaderboard</h2>
      
      <table>
        <thead>
          <tr>
            <th>Rank</th>
            <th>Address</th>
            <th>GUM Balance</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          {leaders.map((leader, index) => (
            <tr key={leader.address}>
              <td>{index + 1}</td>
              <td>
                {leader.address.slice(0, 8)}...
              </td>
              <td>
                {leader.gum.toLocaleString()} GUM
              </td>
              <td>
                {leader.verified ? (
                  <span className="verified">
                    ✅ Verified on-chain
                  </span>
                ) : (
                  <span className="pending">
                    ⏳ Pending sync
                  </span>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
      
      <p className="note">
        💡 Balances are synced to blockchain periodically. 
        Top 10 verified on-chain in real-time!
      </p>
    </div>
  );
}
```

**How It Works:**
1. Fetch from Supabase (fast, includes latest earnings)
2. Verify top 10 on blockchain (trustless proof)
3. Show badge: ✅ Verified or ⏳ Pending sync

**Benefits:**
- ⚡ Fast load (Supabase)
- ✅ Top users verified (blockchain)
- 🔄 Shows latest balances
- 🏆 Best UX!

---

### 3. 💾 Database vs Blockchain Storage

**Here's what lives where:**

#### **Supabase** (Your existing setup):

```sql
-- YOU ALREADY HAVE THESE! ✅
CREATE TABLE user_gum_balances (
  id SERIAL PRIMARY KEY,
  wallet_address VARCHAR(64) UNIQUE NOT NULL,
  total_gum BIGINT DEFAULT 0 NOT NULL,        -- ← Earned on website
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE gum_transactions (
  id SERIAL PRIMARY KEY,
  wallet_address VARCHAR(64) NOT NULL,
  transaction_type VARCHAR(32) NOT NULL,       -- ← 'earned', 'spent', 'transfer_in', etc.
  amount INTEGER NOT NULL,
  source VARCHAR(64) NOT NULL,
  description TEXT,
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

**Used for:**
- ✅ Daily login/checkin tracking
- ✅ Activity-based earning
- ✅ Transaction history
- ✅ Fast queries
- ✅ Leaderboards (fast, unverified)

---

#### **Blockchain** (GumDropsHybrid.cdc):

```cadence
// ON-CHAIN in GumAccount resource
access(all) resource GumAccount {
    access(all) var balance: UFix64              // ← Synced from Supabase OR earned on-chain
    access(all) var totalEarned: UFix64          // ← Total ever earned on-chain
    access(all) var totalSpent: UFix64           // ← Total spent (if any)
    access(all) var totalTransferred: UFix64     // ← Total sent to others on-chain
    access(all) var lastSyncTimestamp: UFix64    // ← When last synced from Supabase
}
```

**Used for:**
- ✅ On-chain transfers (transparent)
- ✅ Special drop claims (verifiable)
- ✅ Leaderboards (trustless)
- ✅ Public balances (anyone can query)

---

### 📊 Complete Data Flow

```
┌─────────────────────────────────────────────────┐
│              SUPABASE (Database)                 │
│  ──────────────────────────────────────         │
│                                                  │
│  user_gum_balances:                              │
│  ┌──────────────┬───────────┬──────────┐        │
│  │ wallet       │ total_gum │ updated  │        │
│  ├──────────────┼───────────┼──────────┤        │
│  │ 0x123...     │ 1,250     │ 10/15/25 │        │
│  │ 0x456...     │ 890       │ 10/15/25 │        │
│  └──────────────┴───────────┴──────────┘        │
│                                                  │
│  gum_transactions:                               │
│  ┌─────────────┬──────┬────────┬─────────┐      │
│  │ wallet      │ type │ amount │ source  │      │
│  ├─────────────┼──────┼────────┼─────────┤      │
│  │ 0x123...    │ earn │ +15    │ login   │      │
│  │ 0x123...    │ earn │ +15    │ checkin │      │
│  │ 0x123...    │ earn │ +10    │ share   │      │
│  └─────────────┴──────┴────────┴─────────┘      │
│                                                  │
│  ✅ Fast queries                                 │
│  ✅ Detailed history                             │
│  ✅ Daily earning tracking                       │
└─────────────────┬───────────────────────────────┘
                  │
                  │ SYNC (Admin runs periodically)
                  │ /api/admin/sync-gum-balance
                  ↓
┌─────────────────────────────────────────────────┐
│         BLOCKCHAIN (GumDropsHybrid.cdc)          │
│  ──────────────────────────────────────         │
│                                                  │
│  GumAccount (0x123...):                          │
│  ┌──────────────┬────────┐                      │
│  │ balance      │ 1,250  │ ← Synced from above  │
│  │ totalEarned  │ 1,250  │                      │
│  │ lastSync     │ Oct 15 │                      │
│  └──────────────┴────────┘                      │
│                                                  │
│  Now user can:                                   │
│  • Transfer to friends (on-chain)               │
│  • Claim special drops (on-chain)               │
│  • Appear on verified leaderboard              │
│                                                  │
│  ✅ Transparent transfers                        │
│  ✅ Verifiable balances                          │
│  ✅ NFT-gated claims                             │
└─────────────────────────────────────────────────┘
```

---

### 🔄 Typical User Journey

#### **Day 1-7: Earning (Supabase only)**
```
1. User logs in → +15 GUM (Supabase)
2. User checks in → +15 GUM (Supabase)
3. User shares → +10 GUM (Supabase)
4. Total in Supabase: 200 GUM

Blockchain balance: 0 GUM (not synced yet)
```

#### **Day 7: Admin Syncs**
```
Admin runs: POST /api/admin/sync-gum-balance
→ Blockchain transaction executed
→ User's GumAccount.balance = 200 GUM
→ Now visible on-chain!
```

#### **Day 8: On-Chain Activity**
```
User transfers 50 GUM to friend (blockchain transaction)
→ User's blockchain balance: 150 GUM
→ Friend's blockchain balance: 50 GUM
→ Both transparent & verifiable!

User claims Halloween drop (blockchain transaction)
→ User's blockchain balance: 250 GUM (150 + 100 from drop)
→ Can't claim twice (on-chain verification)
```

#### **Day 15: Another Sync**
```
User earned 300 more GUM on website (Supabase)
→ Supabase total: 500 GUM
→ Admin syncs again
→ Blockchain balance updated: 550 GUM (250 + 300)
```

---

## 🛠️ Implementation Checklist

### ✅ You Already Have (Supabase):
- [x] `user_gum_balances` table
- [x] `gum_transactions` table
- [x] `gum_sources` table
- [x] `user_gum_cooldowns` table
- [x] `award_gum()` function
- [x] Daily login/checkin logic

### 🆕 Need to Add (Blockchain):
- [ ] Deploy `GumDropsHybrid.cdc` to testnet
- [ ] Users run `setup-gum-account.cdc` (one-time)
- [ ] Admin syncs balances periodically
- [ ] Add "Transfer GUM" feature to website
- [ ] Add "Active Drops" display
- [ ] Add leaderboard (hybrid approach recommended)

### 📝 Optional Supabase Additions:
You might want to track blockchain syncs:

```sql
-- Track when balances are synced to blockchain
CREATE TABLE gum_blockchain_syncs (
  id SERIAL PRIMARY KEY,
  wallet_address VARCHAR(64) NOT NULL,
  synced_balance BIGINT NOT NULL,
  tx_id VARCHAR(128),  -- Flow transaction ID
  synced_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  status VARCHAR(32) DEFAULT 'completed'  -- 'pending', 'completed', 'failed'
);
```

---

## 🎯 Summary

### NFT Gating:
✅ Direct on-chain verification via Flunks.cdc  
✅ Counts actual NFT IDs (`.getIDs().length`)  
✅ Can't be faked  

### Leaderboards:
✅ **Option A**: Blockchain-only (slow, trustless)  
✅ **Option B**: Supabase-only (fast, requires trust)  
✅ **Option C**: Hybrid (BEST! Fast + verified top 10)  

### Database:
✅ **Supabase**: Daily earning, transaction history (you already have this!)  
✅ **Blockchain**: Synced balances, transfers, special drops (new hybrid system)  
✅ **No new SQL needed** - your existing schema is perfect!  

The blockchain contract adds **transparent transfers** and **verifiable drops** on top of your existing Supabase earning system! 🚀
