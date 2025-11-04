# 🎯 GUM Hybrid System - Quick Start

## What You Have Now

**GUM tracked on-chain (but NOT a tradeable token!)**

✅ Earn GUM on website (Supabase) - FREE & instant  
✅ Transfer GUM on blockchain - Transparent & verifiable  
✅ Special drops on blockchain - NFT-gated & time-limited  
✅ Public leaderboards - Trustless rankings  
❌ NOT tradeable on DEXs - It's points, not currency!

---

## 📁 Files Created

### Contract
- `cadence/contracts/GumDropsHybrid.cdc` - Main hybrid GUM system

### Transactions
- `cadence/transactions/gum-hybrid/setup-gum-account.cdc` - User setup (one-time)
- `cadence/transactions/gum-hybrid/transfer-gum.cdc` - Send GUM to friends
- `cadence/transactions/gum-hybrid/claim-special-drop.cdc` - Claim from events
- `cadence/transactions/gum-hybrid/admin-sync-balance.cdc` - Sync from Supabase
- `cadence/transactions/gum-hybrid/admin-create-drop.cdc` - Create events

### Scripts
- `cadence/scripts/gum-hybrid/get-gum-balance.cdc` - Check user balance
- `cadence/scripts/gum-hybrid/get-active-drops.cdc` - List active events
- `cadence/scripts/gum-hybrid/get-drop-info.cdc` - Drop details

### Documentation
- `docs/GUM-HYBRID-SYSTEM.md` - Complete guide with examples

---

## 🚀 How It Works

### 1. **Daily Earning** (Supabase - FREE)
```
User logs in → Supabase awards 15 GUM → Instant, no gas!
```

### 2. **Sync to Blockchain** (Admin - Periodic)
```
Admin syncs balances → Now visible on-chain → Can transfer!
```

### 3. **On-Chain Transfers** (Users)
```
User sends 10 GUM to friend → Blockchain transaction → Public & transparent!
```

### 4. **Special Drops** (Admin creates, users claim)
```
Halloween event → 10,000 GUM pool → Flunks holders claim 100 GUM each
```

---

## 🎮 Use Cases

### Friend Transfers (Blockchain)
```cadence
// Send 50 GUM to a friend with message
flow transactions send cadence/transactions/gum-hybrid/transfer-gum.cdc \
  --arg Address:0x123... \
  --arg UFix64:50.0 \
  --arg String:"Thanks for the help!"
```

### Halloween Event (Blockchain)
```cadence
// Admin creates drop
flow transactions send cadence/transactions/gum-hybrid/admin-create-drop.cdc \
  --arg UFix64:10000.0 \  # 10,000 GUM pool
  --arg UFix64:100.0 \    # 100 per claim
  --arg UFix64:1729900800 \  # Start time
  --arg UFix64:1730505600 \  # End time
  --arg Bool:true \       # Requires Flunks
  --arg String:"Halloween 2025 Drop 🎃"
```

```cadence
// Users claim
flow transactions send cadence/transactions/gum-hybrid/claim-special-drop.cdc \
  --arg UInt64:1  # Drop ID
```

### Leaderboard (Query blockchain)
```javascript
// Get top GUM holders
const topUsers = await getAllUsers();
const sorted = topUsers
  .map(addr => ({ 
    address: addr,
    gum: await getGumBalance(addr)
  }))
  .sort((a, b) => b.gum - a.gum);
```

---

## 🏗️ Architecture

```
WEBSITE (Supabase)          BLOCKCHAIN (Flow)
═══════════════════         ═════════════════

Daily login: +15 GUM   ──┐
Daily check-in: +15    ──┤
Activities: +variable  ──┤
                         │   Sync periodically
(Instant, free)          ├──────────────────→  On-chain balance
                         │                     (GumAccount resource)
                         │                            │
                         │                            ├─→ Transfer to friends
                         │                            ├─→ Claim special drops
                         │                            └─→ Public leaderboard
                         │
Buy NFT with GUM ────────┘ (Deduct in Supabase,
                             mint NFT on-chain)
```

---

## ✨ Key Features

### 1. **Not a Token!**
- ❌ Can't trade on IncrementFi
- ❌ Can't swap for FLOW/USDC  
- ❌ Not in FungibleToken.Vault
- ✅ Tracked in GumAccount resource
- ✅ Transferable between users
- ✅ Verifiable on blockchain

### 2. **Hybrid Benefits**
- **Fast earning** - Supabase (instant)
- **Transparent transfers** - Blockchain (public)
- **Special events** - Blockchain (verifiable)
- **Low cost** - Only sync when needed

### 3. **NFT Integration**
- Flunks holders get special drops
- Must own Flunks to claim certain events
- On-chain verification (can't fake)

### 4. **Admin Control**
- Sync balances from Supabase
- Create limited-time drops
- Award bonus GUM
- Full control over economy

---

## 🎯 For Forte Hackathon

Perfect submission because it demonstrates:

### ✅ Blockchain Innovation
- On-chain ledger (not just database)
- Resource-oriented programming
- NFT gating logic
- Transparent events

### ✅ Practical UX
- Free daily earning (Supabase)
- Optional blockchain features (transfers, drops)
- Hybrid architecture (best of both)

### ✅ Flow Ecosystem
- Uses Flow blockchain
- Integrates with Flunks NFTs
- Could add Flow Actions
- Demonstrates Cadence capabilities

### ✅ User Engagement
- Gamification (daily logins, streaks)
- Social (transfer to friends)
- Events (special drops)
- Leaderboards (rankings)

---

## 📊 Comparison

| Feature | Pure Supabase | Pure Blockchain | **Hybrid (This!)** |
|---------|---------------|-----------------|-------------------|
| Daily earn cost | FREE | $$$$ | FREE ✅ |
| Transfer transparency | Opaque | Transparent | Transparent ✅ |
| Special drops fairness | Can fake | Verifiable | Verifiable ✅ |
| Speed | Instant | Slow | Instant ✅ |
| Leaderboards | Can manipulate | Trustless | Trustless ✅ |
| Tradeable | No | Could be | No (controlled) ✅ |
| Complexity | Low | High | **Medium** ✅ |

---

## 🚀 Next Steps

### 1. Deploy Contract
```bash
flow accounts add-contract GumDropsHybrid cadence/contracts/GumDropsHybrid.cdc --network testnet
```

### 2. Test Transactions
```bash
# Setup account
flow transactions send cadence/transactions/gum-hybrid/setup-gum-account.cdc

# Transfer GUM
flow transactions send cadence/transactions/gum-hybrid/transfer-gum.cdc \
  --arg Address:0x... --arg UFix64:10.0 --arg String:"Test transfer"

# Create drop (admin)
flow transactions send cadence/transactions/gum-hybrid/admin-create-drop.cdc \
  --arg UFix64:1000.0 --arg UFix64:50.0 \
  --arg UFix64:1729900800 --arg UFix64:1730505600 \
  --arg Bool:false --arg String:"Test Drop"

# Claim drop
flow transactions send cadence/transactions/gum-hybrid/claim-special-drop.cdc --arg UInt64:1
```

### 3. Query Balances
```bash
flow scripts execute cadence/scripts/gum-hybrid/get-gum-balance.cdc --arg Address:0x...
flow scripts execute cadence/scripts/gum-hybrid/get-active-drops.cdc
```

### 4. Integrate with Website
- Add "Transfer GUM" button (calls transaction)
- Show active drops (query script)
- Display leaderboard (query all users)
- Sync button (admin function)

---

## 🎉 Summary

**You now have a hybrid GUM system that:**
- ✅ Earns on website (free, instant)
- ✅ Transfers on blockchain (transparent, verifiable)
- ✅ Special drops (NFT-gated, time-limited)
- ✅ NOT a tradeable token (controlled economy)
- ✅ Perfect for Forte hackathon!

**Read the full guide:** `docs/GUM-HYBRID-SYSTEM.md`

This gives you the cool blockchain features (transfers, drops, leaderboards) while keeping daily earning practical!
