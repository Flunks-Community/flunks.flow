# 🎯 GUM Hybrid System - Best of Both Worlds!

## What This Is

**GUM is tracked on-chain but NOT a tradeable token!** It's like a blockchain ledger/scoreboard.

### Think of it like:
- **Xbox Gamerscore** - tracked, visible, transferable between friends, but not sellable
- **Airline Miles** - you can see them, transfer to family, but can't trade on market
- **Reddit Karma** - public score, but not a cryptocurrency

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────┐
│              SUPABASE (Daily Activities)             │
│  ────────────────────────────────────────           │
│  ✅ Daily login: +15 GUM                             │
│  ✅ Daily check-in: +15 GUM                          │
│  ✅ Profile updates: +5 GUM                          │
│  ✅ Social shares: +10 GUM                           │
│                                                      │
│  → Instant, free, tracked in database               │
│  → Periodically synced to blockchain                │
└─────────────────┬───────────────────────────────────┘
                  │
                  │ Sync every 24hrs or on-demand
                  ↓
┌─────────────────────────────────────────────────────┐
│         BLOCKCHAIN (Transfers & Special Drops)       │
│  ────────────────────────────────────────           │
│  ✅ User-to-user transfers (on-chain, transparent)   │
│  ✅ Special event drops (Halloween, milestones)      │
│  ✅ NFT-gated bonuses (Flunks holders only)          │
│  ✅ Public leaderboards (verifiable balances)        │
│                                                      │
│  → GumAccount resource (NOT a token!)               │
│  → Transparent, immutable history                   │
└─────────────────────────────────────────────────────┘
```

---

## ✨ Key Features

### 1. **On-Chain Transfers** (Blockchain)
Users can send GUM to each other **on-chain**:
- Transparent (everyone can see)
- Immutable (can't be faked)
- With messages ("Thanks for the help!")
- But NOT tradeable on DEXs (it's not a token!)

### 2. **Special Drops** (Blockchain)
Admin creates limited-time airdrops:
- Halloween event: 10,000 GUM pool
- Milestone celebration: 50 GUM per claim
- NFT-gated: Requires Flunks ownership
- Time-limited: Start/end timestamps

### 3. **Supabase Sync** (Hybrid)
Backend syncs balances from Supabase to blockchain:
- User earns 100 GUM on website (Supabase)
- Admin syncs to blockchain (now visible on-chain)
- User can now transfer on-chain
- Leaderboard shows verified balances

### 4. **Not a Token!** 
- ❌ Can't trade on DEXs
- ❌ Can't swap for Flow/USDC
- ❌ Not in user's vault
- ✅ Tracked in GumAccount resource
- ✅ Transferable to friends
- ✅ Spendable on your site only

---

## 🔧 How It Works

### User Flow: Earning GUM

```typescript
// 1. User logs in to website
// 2. Supabase awards 15 GUM (instant, free)
await awardGum(walletAddress, 'daily_login', { ... });

// 3. User earns 100 total GUM over a week (all in Supabase)

// 4. Admin syncs to blockchain (once per day or on-demand)
// This makes it "official" and visible on-chain
const txId = await syncGumBalance(walletAddress, 100);

// 5. Now user can transfer on-chain or claim special drops
```

### User Flow: Transferring GUM

```cadence
// User sends GUM to friend (on-chain transaction)
import GumDropsHybrid from 0xYOUR_ADDRESS

transaction(recipient: Address, amount: UFix64, message: String?) {
    let gumAccount: &GumDropsHybrid.GumAccount
    
    prepare(signer: auth(Storage, BorrowValue) &Account) {
        self.gumAccount = signer.storage.borrow<&GumDropsHybrid.GumAccount>(
            from: GumDropsHybrid.GumAccountStoragePath
        ) ?? panic("No GUM account")
    }
    
    execute {
        self.gumAccount.transfer(
            amount: amount,
            to: recipient,
            message: message
        )
    }
}
```

**Result:**
- Sender loses GUM (on-chain)
- Recipient gains GUM (on-chain)
- Event emitted (transparent)
- Transaction visible on Flowscan

### User Flow: Claiming Special Drop

```cadence
// User claims Halloween drop (requires Flunks NFT)
import GumDropsHybrid from 0xYOUR_ADDRESS
import Flunks from 0xYOUR_ADDRESS

transaction(dropID: UInt64) {
    let gumAccount: &GumDropsHybrid.GumAccount
    let flunksCollection: &{NonFungibleToken.CollectionPublic}?
    
    prepare(signer: auth(Storage, BorrowValue) &Account) {
        self.gumAccount = signer.storage.borrow<&GumDropsHybrid.GumAccount>(
            from: GumDropsHybrid.GumAccountStoragePath
        ) ?? panic("No GUM account")
        
        // Optional: Get Flunks collection if they have it
        self.flunksCollection = signer.capabilities.get<&{NonFungibleToken.CollectionPublic}>(
            Flunks.CollectionPublicPath
        ).borrow()
    }
    
    execute {
        GumDropsHybrid.claimSpecialDrop(
            dropID: dropID,
            claimer: self.gumAccount,
            flunksCollection: self.flunksCollection
        )
    }
}
```

**Result:**
- User gets 50 GUM (added to on-chain balance)
- Can't claim twice
- Must own Flunks if required
- Must be within time window

---

## 📊 Comparison: Hybrid vs Other Approaches

| Feature | Full Supabase | Full Blockchain | **Hybrid (This!)** |
|---------|---------------|-----------------|-------------------|
| Daily earning | ✅ Free | ❌ Gas fees | ✅ Free (Supabase) |
| Transfers | ⚠️ Opaque | ✅ Transparent | ✅ Transparent (blockchain) |
| Special drops | ⚠️ Can fake | ✅ Verifiable | ✅ Verifiable (blockchain) |
| Speed | ✅ Instant | ❌ Slow | ✅ Instant (Supabase) |
| Cost | ✅ Free | ❌ Expensive | ✅ Mostly free |
| Leaderboards | ⚠️ Can manipulate | ✅ Trustless | ✅ Trustless (blockchain) |
| Tradeable | ❌ No | ⚠️ Yes (if token) | ❌ No (it's not a token!) |

---

## 🎮 Use Cases

### 1. **Friend Transfers** (On-Chain)
- "Thanks for the tip!" → Send 10 GUM
- Birthday gift → Send 100 GUM
- Team reward → Send 50 GUM to teammates
- **Public & transparent** on blockchain

### 2. **Special Events** (On-Chain)
- **Halloween 2025**: 10,000 GUM pool, 100 per claim, Flunks holders only
- **1 Million Users**: 50,000 GUM pool, 50 per claim, everyone
- **Weekly Challenges**: 5,000 GUM pool, 25 per claim, time-limited
- **Verifiable & fair** on blockchain

### 3. **Leaderboards** (On-Chain)
- Top GUM holders (can't fake on-chain balances)
- Most generous (most GUM transferred)
- Early adopters (oldest GUM accounts)
- **Trustless rankings** from blockchain data

### 4. **Daily Earning** (Supabase)
- Login bonus: +15 GUM (instant)
- Check-in: +15 GUM (instant)
- Activities: +variable GUM (instant)
- **Free & fast** in database

### 5. **Spending** (Either!)
- **Supabase**: Simple purchases (database deduction)
- **Blockchain**: Special NFT sales (on-chain proof)
- **Hybrid**: Best of both!

---

## 🚀 Implementation Guide

### Step 1: Setup User Account (One-time)

```cadence
// cadence/transactions/setup-gum-account.cdc
import GumDropsHybrid from "./contracts/GumDropsHybrid.cdc"

transaction {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Check if already setup
        if signer.storage.borrow<&GumDropsHybrid.GumAccount>(
            from: GumDropsHybrid.GumAccountStoragePath
        ) == nil {
            // Create GUM account
            let account <- GumDropsHybrid.createGumAccount()
            signer.storage.save(<-account, to: GumDropsHybrid.GumAccountStoragePath)
            
            // Create public capability
            let cap = signer.capabilities.storage.issue<&GumDropsHybrid.GumAccount>(
                GumDropsHybrid.GumAccountStoragePath
            )
            signer.capabilities.publish(cap, at: GumDropsHybrid.GumAccountPublicPath)
        }
    }
}
```

### Step 2: Sync Balance from Supabase (Admin)

```typescript
// Backend API: /api/admin/sync-gum-balance
import * as fcl from '@onflow/fcl';

export async function POST(req: Request) {
  const { userAddress } = await req.json();
  
  // 1. Get Supabase balance
  const { data } = await supabase
    .from('user_gum_balances')
    .select('total_gum')
    .eq('wallet_address', userAddress)
    .single();
  
  const supabaseBalance = data.total_gum;
  
  // 2. Sync to blockchain
  const txId = await fcl.mutate({
    cadence: `
      import GumDropsHybrid from 0xYOUR_ADDRESS
      
      transaction(userAddress: Address, balance: UFix64) {
        let admin: &GumDropsHybrid.Admin
        
        prepare(signer: auth(Storage, BorrowValue) &Account) {
          self.admin = signer.storage.borrow<&GumDropsHybrid.Admin>(
            from: GumDropsHybrid.AdminStoragePath
          ) ?? panic("Not admin")
        }
        
        execute {
          self.admin.syncUserBalance(
            userAddress: userAddress,
            supabaseBalance: balance
          )
        }
      }
    `,
    args: (arg, t) => [
      arg(userAddress, t.Address),
      arg(supabaseBalance.toFixed(8), t.UFix64)
    ],
    authorizations: [adminAuthz],
    limit: 1000
  });
  
  return Response.json({ success: true, txId });
}
```

### Step 3: Transfer GUM (User)

```typescript
// Frontend component
export function TransferGUM({ userAddress }) {
  const handleTransfer = async (to: string, amount: number, message: string) => {
    const txId = await fcl.mutate({
      cadence: transferGumCadence, // See transaction above
      args: (arg, t) => [
        arg(to, t.Address),
        arg(amount.toFixed(8), t.UFix64),
        arg(message, t.Optional(t.String))
      ],
      proposer: fcl.currentUser,
      authorizations: [fcl.currentUser],
      limit: 100
    });
    
    alert(`Transfer successful! TX: ${txId}`);
  };
  
  return <TransferForm onSubmit={handleTransfer} />;
}
```

### Step 4: Create Special Drop (Admin)

```typescript
// Admin creates Halloween drop
const dropID = await fcl.mutate({
  cadence: `
    import GumDropsHybrid from 0xYOUR_ADDRESS
    
    transaction(
      totalAmount: UFix64,
      amountPerClaim: UFix64,
      startTime: UFix64,
      endTime: UFix64,
      requiresFlunks: Bool,
      description: String
    ) {
      let admin: &GumDropsHybrid.Admin
      
      prepare(signer: auth(Storage, BorrowValue) &Account) {
        self.admin = signer.storage.borrow<&GumDropsHybrid.Admin>(
          from: GumDropsHybrid.AdminStoragePath
        ) ?? panic("Not admin")
      }
      
      execute {
        let dropID = self.admin.createSpecialDrop(
          totalAmount: totalAmount,
          amountPerClaim: amountPerClaim,
          startTime: startTime,
          endTime: endTime,
          requiresFlunks: requiresFlunks,
          description: description
        )
        
        log("Created drop #".concat(dropID.toString()))
      }
    }
  `,
  args: (arg, t) => [
    arg("10000.0", t.UFix64),        // 10,000 GUM pool
    arg("100.0", t.UFix64),           // 100 per claim
    arg(startTimestamp, t.UFix64),
    arg(endTimestamp, t.UFix64),
    arg(true, t.Bool),                // Requires Flunks
    arg("Halloween 2025 Drop", t.String)
  ],
  authorizations: [adminAuthz],
  limit: 1000
});
```

---

## 🏆 For Forte Hackathon

This hybrid approach is **perfect** for the hackathon because:

### ✅ Blockchain Features (Cool & Innovative)
- On-chain GUM transfers (transparent, verifiable)
- Special drops with NFT gating (smart contract logic)
- Public leaderboards (trustless data)
- Immutable history (blockchain benefits)

### ✅ Practical Implementation (User-Friendly)
- Free daily earning (Supabase)
- Fast interactions (no gas for earning)
- Scalable (database for high-frequency actions)
- Cost-effective (blockchain only when needed)

### ✅ Flow Actions Compatible
You can create Flow Actions for:
- `TransferGum` - Source interface
- `ClaimSpecialDrop` - Swapper interface
- Composable GUM workflows

### ✅ Demonstrates Best Practices
- Hybrid architecture (off-chain + on-chain)
- Resource-oriented programming (GumAccount)
- Event emissions (transparent actions)
- Access control (Admin resource)

---

## 📋 Summary

**GUM is NOT a token, it's an on-chain points ledger!**

- ✅ Earn on website (Supabase) - free & instant
- ✅ Transfer on blockchain - transparent & verifiable
- ✅ Special drops on blockchain - fair & limited-time
- ✅ NOT tradeable on DEXs - controlled economy
- ✅ Best of both worlds - hybrid approach

This gives you cool blockchain features (transfers, drops, leaderboards) while keeping daily earning practical (free, fast, scalable).

**Perfect for Forte hackathon submission!** 🎯
