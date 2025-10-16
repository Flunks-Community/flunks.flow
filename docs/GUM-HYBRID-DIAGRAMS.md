# GUM Hybrid System - Visual Architecture

## 📊 Complete System Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                      FLUNKS WEBSITE                               │
└──────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┴─────────────────────┐
        │                                           │
        ▼                                           ▼
┌───────────────────────┐              ┌────────────────────────┐
│   SUPABASE (Fast)     │              │  BLOCKCHAIN (Verified) │
│   ───────────────     │              │  ─────────────────     │
│                       │              │                        │
│  Daily Earning:       │   SYNC       │  GumAccount Resource:  │
│  • Login: +15 GUM ────┼──────────────▶  • balance: 1,250     │
│  • Checkin: +15 GUM   │   (Admin)    │  • totalEarned        │
│  • Activities: +var   │              │  • totalTransferred   │
│                       │              │  • lastSync           │
│  Database Tables:     │              │                        │
│  • user_gum_balances  │              │  Special Features:     │
│  • gum_transactions   │              │  • Transfer to friends │
│  • gum_sources        │   READ       │  • Claim special drops │
│  • gum_cooldowns  ────┼──────────────▶  • NFT-gated bonuses  │
│                       │   (Query)    │  • Public leaderboard  │s
│  Admin API:           │              │                        │
│  • /api/award-gum     │              │  Flunks.cdc:          │
│  • /api/claim-daily   │   VERIFY     │  • Owns Flunks NFTs?  │
│  • /api/sync-balance ─┼──────────────▶  • getIDs().length > 0│
│                       │   (Check)    │  • On-chain proof     │
└───────────────────────┘              └────────────────────────┘
         │                                         │
         │                                         │
         ▼                                         ▼
┌───────────────────────┐              ┌────────────────────────┐
│  Leaderboard (Fast)   │              │ Leaderboard (Trustless)│
│  ─────────────────    │              │ ───────────────────    │
│  SELECT * FROM        │              │  fcl.query({           │
│    user_gum_balances  │              │    cadence: script,    │
│    ORDER BY total_gum │              │    args: [addresses]   │
│    LIMIT 100          │              │  })                    │
└───────────────────────┘              └────────────────────────┘
```

---

## 🔄 User Flow: Earning & Syncing

```
DAY 1-7: Earning on Website (Supabase)
══════════════════════════════════════

User Activity          Supabase DB           Blockchain
─────────────          ───────────           ──────────
Login         ──────▶  +15 GUM added         (not synced)
                       total_gum: 15

Checkin       ──────▶  +15 GUM added         (not synced)
                       total_gum: 30

Share         ──────▶  +10 GUM added         (not synced)
                       total_gum: 40

Profile       ──────▶  +5 GUM added          (not synced)
                       total_gum: 45
                       
                       ⚡ INSTANT, FREE


DAY 7: Admin Syncs to Blockchain
═══════════════════════════════════

Admin Action                    Blockchain Transaction
────────────                    ─────────────────────
POST /api/admin/sync ────────▶  transaction {
  wallet: 0x123...                prepare(admin) {
  balance: 45                       admin.syncUserBalance(
                                      0x123...,
                                      45.0
                                    )
                                  }
                                }
                                
                                ✅ GumAccount.balance = 45
                                ✅ Now visible on-chain!
                                ✅ Can transfer to friends
                                ✅ Can claim drops


DAY 8+: On-Chain Activities
═══════════════════════════════

User transfers 10 GUM to friend
────────────────────────────────
Blockchain TX ──────▶  User balance: 35 GUM
                       Friend balance: +10 GUM
                       ✅ Transparent & verifiable!

User claims Halloween drop (100 GUM)
────────────────────────────────────
Blockchain TX ──────▶  User balance: 135 GUM (35 + 100)
                       ✅ Requires Flunks NFT (verified on-chain)
                       ✅ Can't claim twice
                       ✅ Time-limited (start/end)


Continues earning on website
─────────────────────────────
Daily login   ──────▶  Supabase: +15 GUM
Checkin       ──────▶  Supabase: +15 GUM
                       (total earned since last sync: 30)


DAY 15: Next Sync
═════════════════

Admin syncs again  ──────▶  GumAccount.balance = 165
                            (135 on-chain + 30 from Supabase)
```

---

## 🎯 NFT Gating: How It Works

```
User Claims Special Drop
════════════════════════

1. USER SUBMITS TRANSACTION
   ┌─────────────────────────────────┐
   │ transaction(dropID: 1) {        │
   │   prepare(signer) {             │
   │     // Get user's Flunks NFTs   │
   │     self.flunksCollection =     │
   │       signer.capabilities       │
   │         .get(Flunks.PublicPath) │
   │         .borrow()               │◀───┐
   │   }                             │    │
   └─────────────────────────────────┘    │
                                          │
2. CONTRACT CHECKS FLUNKS                 │
   ┌─────────────────────────────────┐    │
   │ access(all) fun claimDrop() {   │    │
   │   let hasFlunks =               │    │
   │     flunksCollection != nil &&  │────┘
   │     flunksCollection            │
   │       .getIDs()  ──────────────────┐
   │       .length > 0               │  │
   │ }                               │  │
   └─────────────────────────────────┘  │
                                        │
3. VERIFIES WITH FLUNKS CONTRACT        │
   ┌─────────────────────────────────┐  │
   │  Flunks.cdc                     │  │
   │  ──────────                     │  │
   │  resource Collection {          │  │
   │    access(all) var ownedNFTs    │◀─┘
   │                                 │
   │    access(all) fun getIDs():    │
   │      [UInt64] {                 │
   │      return self.ownedNFTs.keys │
   │    }                            │
   │  }                              │
   └─────────────────────────────────┘
                │
                ▼
   ┌─────────────────────────────────┐
   │ RESULT:                         │
   │ hasFlunks = true/false          │
   │                                 │
   │ If true:  ✅ Claim 100 GUM      │
   │ If false: ❌ Panic error         │
   └─────────────────────────────────┘
```

---

## 📊 Leaderboard Options

### Option A: Blockchain Leaderboard (Slow but Trustless)

```
Frontend Request
│
├─▶ Get all user addresses (Supabase)
│   SELECT wallet_address FROM user_gum_balances
│
├─▶ Query blockchain for each balance (Flow)
│   fcl.query({
│     cadence: `
│       import GumDropsHybrid from 0x...
│       
│       access(all) fun main(addresses: [Address]): {Address: UFix64} {
│         let balances: {Address: UFix64} = {}
│         
│         for address in addresses {
│           let account = getAccount(address)
│           let gumAccount = account.capabilities
│             .get<&GumDropsHybrid.GumAccount>(/public/GumAccount)
│             .borrow()
│           
│           if let account = gumAccount {
│             balances[address] = account.getInfo().balance
│           }
│         }
│         
│         return balances
│       }
│     `
│   })
│
└─▶ Sort and display
    [
      { address: "0x123...", gum: 1250, verified: true },
      { address: "0x456...", gum: 890, verified: true },
      ...
    ]

✅ Trustless (can't fake)
❌ Slow (blockchain queries)
```

### Option B: Supabase Leaderboard (Fast but Requires Trust)

```
Frontend Request
│
├─▶ Query Supabase directly
│   const { data } = await supabase
│     .from('user_gum_balances')
│     .select('wallet_address, total_gum')
│     .order('total_gum', { ascending: false })
│     .limit(100)
│
└─▶ Display
    [
      { address: "0x123...", gum: 1250, verified: false },
      { address: "0x456...", gum: 890, verified: false },
      ...
    ]

✅ Fast (database query)
❌ Could be manipulated
```

### Option C: Hybrid Leaderboard (BEST!)

```
Frontend Request
│
├─▶ Get Supabase leaderboard (fast)
│   const supabaseLeaders = await getSupabaseLeaderboard(100)
│
├─▶ Verify top 10 on blockchain (trustless)
│   const top10Addresses = supabaseLeaders.slice(0, 10).map(l => l.address)
│   const blockchainBalances = await fcl.query({
│     cadence: verifyBalancesScript,
│     args: [top10Addresses]
│   })
│
└─▶ Display with verification badges
    [
      { address: "0x123...", gum: 1250, verified: ✅ },  ← Top 10 verified
      { address: "0x456...", gum: 890, verified: ✅ },
      ...
      { address: "0xabc...", gum: 45, verified: ⏳ },   ← Rest pending
    ]

✅ Fast (Supabase)
✅ Top users verified (blockchain)
✅ Best UX!
```

---

## 💾 Data Storage Summary

```
┌─────────────────────────────────────────────────────────────┐
│                    SUPABASE (Your Existing DB)               │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  user_gum_balances                                           │
│  ┌─────────┬───────────┬──────────┬──────────┬──────────┐  │
│  │ id      │ wallet    │ total_gum│ created  │ updated  │  │
│  ├─────────┼───────────┼──────────┼──────────┼──────────┤  │
│  │ 1       │ 0x123...  │ 1250     │ Oct 1    │ Oct 15   │  │
│  │ 2       │ 0x456...  │ 890      │ Oct 3    │ Oct 15   │  │
│  └─────────┴───────────┴──────────┴──────────┴──────────┘  │
│                                                              │
│  gum_transactions                                            │
│  ┌────┬──────────┬──────────┬────────┬──────────┬─────────┐│
│  │ id │ wallet   │ type     │ amount │ source   │ created ││
│  ├────┼──────────┼──────────┼────────┼──────────┼─────────┤│
│  │ 1  │ 0x123... │ earned   │ 15     │ login    │ Oct 15  ││
│  │ 2  │ 0x123... │ earned   │ 15     │ checkin  │ Oct 15  ││
│  │ 3  │ 0x123... │ spent    │ 100    │ nft_buy  │ Oct 14  ││
│  └────┴──────────┴──────────┴────────┴──────────┴─────────┘│
│                                                              │
│  ✅ Already exists!                                          │
│  ✅ No changes needed!                                       │
│  ✅ Tracks daily earning                                     │
│  ✅ Fast queries                                             │
└─────────────────────────────────────────────────────────────┘

                            SYNC (Admin)
                                 │
                                 ▼

┌─────────────────────────────────────────────────────────────┐
│                BLOCKCHAIN (GumDropsHybrid.cdc)               │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  GumAccount (0x123...)                                       │
│  ┌────────────────────┬────────┐                            │
│  │ balance            │ 1250   │ ← Synced from Supabase     │
│  │ totalEarned        │ 1250   │                            │
│  │ totalSpent         │ 0      │                            │
│  │ totalTransferred   │ 100    │ ← On-chain transfers       │
│  │ lastSyncTimestamp  │ Oct 15 │                            │
│  └────────────────────┴────────┘                            │
│                                                              │
│  GumAccount (0x456...)                                       │
│  ┌────────────────────┬────────┐                            │
│  │ balance            │ 890    │                            │
│  │ totalEarned        │ 890    │                            │
│  │ totalSpent         │ 0      │                            │
│  │ totalTransferred   │ 0      │                            │
│  │ lastSyncTimestamp  │ Oct 15 │                            │
│  └────────────────────┴────────┘                            │
│                                                              │
│  SpecialDrop #1 (Halloween)                                  │
│  ┌────────────────────┬────────┐                            │
│  │ totalAmount        │ 10000  │                            │
│  │ amountPerClaim     │ 100    │                            │
│  │ remainingAmount    │ 8500   │                            │
│  │ requiresFlunks     │ true   │                            │
│  │ claimers           │ {...}  │ ← Who claimed              │
│  └────────────────────┴────────┘                            │
│                                                              │
│  ✅ New contract!                                            │
│  ✅ Transparent transfers                                    │
│  ✅ Verifiable drops                                         │
│  ✅ NFT-gated                                                │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 Key Takeaways

1. **NFT Gating**: Direct on-chain check of Flunks.cdc (`.getIDs().length`)
2. **Leaderboard**: Use hybrid approach (Supabase + verify top 10 on-chain)
3. **Database**: Keep your existing Supabase schema (no changes needed!)
4. **Storage**: Supabase for earning, blockchain for transfers/drops
5. **Sync**: Admin periodically syncs Supabase → Blockchain

**You already have the database setup! Just add the blockchain layer for transfers and special drops.** 🚀
