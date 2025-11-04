# Flow Actions Autopush - Visual Guide

## 🎃 How It Works: Halloween Autopush with Flow Actions

```
                                HALLOWEEN 2025
                            October 31, 12:00 AM UTC
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         VERCEL CRON JOB                             │
│                   /api/halloween/autopush                           │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      SUPABASE DATABASE                              │
│  ─────────────────────────────────────────────────                 │
│                                                                     │
│  Query eligible users:                                              │
│  SELECT wallet_address, total_gum                                   │
│  FROM user_gum_balances                                             │
│  WHERE total_gum >= 50                                              │
│                                                                     │
│  Results:                                                           │
│  ┌──────────────────────┬──────────┐                               │
│  │ Address              │ GUM      │                               │
│  ├──────────────────────┼──────────┤                               │
│  │ 0x1234...            │ 50       │ ─┐                            │
│  │ 0x5678...            │ 120      │  │                            │
│  │ 0x9abc...            │ 85       │  │                            │
│  │ ...                  │ ...      │  │                            │
│  └──────────────────────┴──────────┘  │                            │
└───────────────────────────────────────┼────────────────────────────┘
                                        │
                                        │ For each user
                                        ▼
┌─────────────────────────────────────────────────────────────────────┐
│                   FLOW ACTIONS WORKFLOW                             │
│  ─────────────────────────────────────────────────                 │
│                                                                     │
│  1. Check Flunks Ownership (on-chain)                               │
│     ├─ Query user's FlunksCollection                                │
│     ├─ If no Flunks: SKIP                                          │
│     └─ If has Flunks: CONTINUE ✓                                   │
│                                                                     │
│  2. Calculate Total                                                 │
│     ├─ Supabase Balance: 50 GUM                                    │
│     ├─ Halloween Bonus: +100 GUM                                   │
│     └─ Total: 150 GUM                                              │
│                                                                     │
│  3. Create Flow Actions Components                                  │
│     ┌────────────────────────────────────┐                         │
│     │  SupabaseGumSource                 │                         │
│     │  ├─ userAddress: 0x1234...         │                         │
│     │  ├─ supabaseBalance: 150.0         │                         │
│     │  └─ uniqueID: "uuid-123..."        │                         │
│     └────────────────────────────────────┘                         │
│                      │                                              │
│                      ▼                                              │
│     ┌────────────────────────────────────┐                         │
│     │  withdrawAvailable()               │                         │
│     │  Returns: VirtualGumVault(150)     │                         │
│     └────────────────────────────────────┘                         │
│                      │                                              │
│                      ▼                                              │
│     ┌────────────────────────────────────┐                         │
│     │  GumAccountSink                    │                         │
│     │  ├─ recipient: 0x1234...           │                         │
│     │  └─ uniqueID: "uuid-123..."        │                         │
│     └────────────────────────────────────┘                         │
│                      │                                              │
│                      ▼                                              │
│     ┌────────────────────────────────────┐                         │
│     │  depositCapacity()                 │                         │
│     │  GumAccount.deposit(150)           │                         │
│     └────────────────────────────────────┘                         │
│                                                                     │
└─────────────────────────────┬───────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      FLOW BLOCKCHAIN                                │
│  ─────────────────────────────────────────────────                 │
│                                                                     │
│  User 0x1234... GumAccount:                                         │
│  ├─ Before: 0 GUM                                                   │
│  ├─ After: 150 GUM ✅                                               │
│  └─ Event: GumTransferred(amount: 150, source: "halloween_2025")   │
│                                                                     │
│  UniqueIdentifier: "uuid-123..."                                    │
│  ├─ SourceWithdrawn event                                          │
│  ├─ SinkDeposited event                                            │
│  └─ GumSynced event                                                │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        USER WAKES UP                                │
│  ─────────────────────────────────────────────────                 │
│                                                                     │
│  Opens wallet...                                                    │
│                                                                     │
│  🎃 "WHOA! 150 GUM appeared!"                                      │
│  🎃 "I didn't claim anything!"                                     │
│  🎃 "Happy Halloween from Flunks! 👻"                              │
│                                                                     │
│  Can now:                                                           │
│  ├─ Transfer to friends                                            │
│  ├─ Claim special drops                                            │
│  ├─ Participate in on-chain activities                             │
│  └─ Show off in wallet! 😎                                         │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Flow Actions Components

### Source: SupabaseGumSource

```
┌──────────────────────────────────────┐
│     SupabaseGumSource                │
│                                      │
│  Purpose: Represent Supabase GUM     │
│           being moved to blockchain  │
│                                      │
│  Properties:                         │
│  ├─ userAddress: Address             │
│  ├─ supabaseBalance: UFix64          │
│  └─ uniqueID: UniqueIdentifier       │
│                                      │
│  Functions:                          │
│  ├─ minimumAvailable()               │
│  │   └─ Returns: supabaseBalance     │
│  │                                    │
│  └─ withdrawAvailable(max)           │
│      └─ Returns: VirtualGumVault     │
│                                      │
└──────────────────────────────────────┘
```

### Sink: GumAccountSink

```
┌──────────────────────────────────────┐
│       GumAccountSink                 │
│                                      │
│  Purpose: Deposit GUM to user's      │
│           on-chain GumAccount        │
│                                      │
│  Properties:                         │
│  ├─ recipient: Address               │
│  └─ uniqueID: UniqueIdentifier       │
│                                      │
│  Functions:                          │
│  ├─ minimumCapacity()                │
│  │   └─ Returns: UFix64.max          │
│  │                                    │
│  └─ depositCapacity(vault)           │
│      └─ GumAccount.deposit(amount)   │
│                                      │
└──────────────────────────────────────┘
```

### Vault: VirtualGumVault

```
┌──────────────────────────────────────┐
│      VirtualGumVault                 │
│                                      │
│  Purpose: Represent Supabase GUM     │
│           as a Flow vault            │
│                                      │
│  Properties:                         │
│  └─ balance: UFix64                  │
│                                      │
│  Functions:                          │
│  ├─ withdraw(amount)                 │
│  ├─ deposit(vault)                   │
│  ├─ createEmptyVault()               │
│  └─ isAvailableToWithdraw(amount)    │
│                                      │
│  Note: This is NOT real GUM token    │
│        It's a marker for Flow Actions│
│                                      │
└──────────────────────────────────────┘
```

---

## 📊 Data Flow

### Step-by-Step

```
1. TRIGGER (Cron)
   └─▶ Oct 31, 12:00 AM UTC

2. QUERY (Supabase)
   └─▶ SELECT wallet_address, total_gum
       WHERE total_gum >= 50

3. FILTER (On-chain check)
   └─▶ IF user.hasFlunks() THEN process

4. CALCULATE (Addition)
   └─▶ total = supabase_gum + 100

5. SOURCE (Flow Actions)
   └─▶ SupabaseGumSource(total)
       └─▶ withdrawAvailable()
           └─▶ VirtualGumVault(total)

6. SINK (Flow Actions)
   └─▶ GumAccountSink(user)
       └─▶ depositCapacity(vault)
           └─▶ GumAccount.deposit(total)

7. RECORD (Logging)
   └─▶ INSERT INTO halloween_autopush_log
       └─▶ tx_id, wallet, amount, timestamp

8. REPEAT
   └─▶ Next user (with 2 second delay)
```

---

## 🎯 Key Advantages

### vs Manual Claiming

```
MANUAL CLAIMING                  FLOW ACTIONS AUTOPUSH
┌──────────────────┐            ┌──────────────────┐
│ 1. User visits   │            │ 1. Cron runs     │
│ 2. User logs in  │            │ 2. Auto-checks   │
│ 3. User clicks   │            │ 3. Auto-deposits │
│ 4. User signs TX │            │ 4. User wakes up │
│ 5. GUM appears   │            │ 5. GUM is there! │
└──────────────────┘            └──────────────────┘
      
User Effort: HIGH 😓            User Effort: ZERO 😎
Completion: ~60%                Completion: 100%
Surprise: Low                   Surprise: HIGH 🎁
```

---

## 🔍 Traceability with UniqueIdentifier

```
Transaction UUID: "uuid-123-halloween-user-0x1234"
│
├─▶ Event: SourceWithdrawn
│   ├─ sourceType: SupabaseGumSource
│   ├─ amount: 150.0
│   ├─ userAddress: 0x1234...
│   └─ uniqueID: uuid-123...
│
├─▶ Event: SinkDeposited
│   ├─ sinkType: GumAccountSink
│   ├─ amount: 150.0
│   ├─ recipient: 0x1234...
│   └─ uniqueID: uuid-123...
│
└─▶ Event: GumSynced
    ├─ owner: 0x1234...
    ├─ oldBalance: 0.0
    ├─ newBalance: 150.0
    └─ uniqueID: uuid-123...

✅ Full audit trail for each user!
```

---

## 💰 Cost Analysis

### For 1000 Users

```
Gas Cost per Transaction: ~0.0001 FLOW
Number of Users: 1000
Total Gas: ~0.1 FLOW
FLOW Price: ~$0.70
Total Cost: ~$0.07 (7 CENTS!)

Per User Cost: $0.00007 (basically free!)
Per User Value: 150 GUM
ROI: Engagement + Community Love = Priceless! 🎃

🎉 Flow blockchain is EXTREMELY cheap for transactions!
```

---

## 🚀 Future Composability

### What Else You Can Do

```
1. AUTO-SWAP
   SupabaseGumSource → Swapper → FlowToken Sink
   └─▶ Users get FLOW instead of GUM!

2. AUTO-STAKE
   SupabaseGumSource → Staking Sink
   └─▶ Auto-stake rewards for users!

3. AUTO-SPLIT
   SupabaseGumSource → 50% GUM + 50% FLOW
   └─▶ Diversified rewards!

4. CONDITIONAL
   IF price > threshold THEN swap ELSE hold
   └─▶ Smart auto-execution!
```

---

## 📅 Timeline

### Implementation Schedule

```
Week 1 (This Week)
├─ Day 1-2: Add Flow Actions to SemesterZero.cdc
├─ Day 3-4: Create /api/halloween/autopush
├─ Day 5-6: Test on testnet with 5 users
└─ Day 7: Review & adjust

Week 2 (Next Week)
├─ Day 1-2: Add monitoring/logging
├─ Day 3-4: Final testnet batch test
├─ Day 5-6: Deploy to mainnet
└─ Day 7: Schedule cron for Oct 31

Halloween (Oct 31)
└─ 12:00 AM: Autopush executes! 🎃

Post-Halloween
└─ Analyze results
└─ Prepare for Christmas! 🎄
```

---

## ✅ Success Metrics

### How to Measure

```
Completion Rate
└─▶ autopushed_users / eligible_users × 100%

Gas Efficiency
└─▶ total_gas_cost / total_users

User Delight
└─▶ social_media_mentions + "wow" reactions 🎃

Technical Achievement
└─▶ Hackathon judges' scores 🏆

Reusability
└─▶ Can we use this for Christmas? YES! ✅
```

---

## 🎓 Learning Value

### What This Teaches

✅ **Flow Actions** - New Forte upgrade  
✅ **Source/Sink Pattern** - DeFi composability  
✅ **Automation** - Cron + blockchain  
✅ **Integration** - Supabase ↔ Flow  
✅ **Event Tracing** - UniqueIdentifier  
✅ **Production Skills** - Real-world deployment  

---

## Summary

**Flow Actions Autopush** = 
- 🤖 Fully automated
- 📅 Scheduled execution  
- 💾 Supabase integration
- ⛓️ Blockchain finality
- 🎁 Surprise factor
- 🏆 Hackathon ready

**Perfect for Halloween 2025!** 🎃👻
