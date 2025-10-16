# GUM Sync Costs - Quick Reference

## 💰 TL;DR

**Yes, syncing costs money!** Each sync = Flow transaction = gas fees

**Cost per sync:** ~$0.00003 (basically free)  
**BUT at scale:** Can add up fast!

---

## 📊 Cost At Scale (Monthly)

```
┌────────────────────────────────────────────────────────┐
│  DAILY SYNC (All Users, Every Day)                     │
├────────────────────────────────────────────────────────┤
│  1,000 users   = $1/month       ✅ Affordable          │
│  10,000 users  = $11/month      ✅ Reasonable          │
│  100,000 users = $105/month     ⚠️ Getting expensive   │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│  HOURLY SYNC (Frequent)                                │
├────────────────────────────────────────────────────────┤
│  1,000 users   = $25/month      ❌ Wasteful            │
│  10,000 users  = $252/month     ❌ Very expensive      │
│  100,000 users = $2,520/month   🚨 TOO EXPENSIVE!      │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│  SMART SYNC (Event-Driven + Daily Backup) ⭐           │
├────────────────────────────────────────────────────────┤
│  1,000 users   = $0.05/month    ✅ Very cheap!         │
│  10,000 users  = $0.50/month    ✅ Excellent!          │
│  100,000 users = $5/month       ✅ Affordable!         │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│  LAZY SYNC (Only When Needed) ⭐⭐                     │
├────────────────────────────────────────────────────────┤
│  1,000 users   = $0.01/month    ✅ Cheapest!           │
│  10,000 users  = $0.10/month    ✅ Best value!         │
│  100,000 users = $1/month       ✅ Incredibly cheap!   │
└────────────────────────────────────────────────────────┘
```

---

## ⚠️ Downsides of Syncing Too Often

### 1. 💰 Cost Multiplies
```
Daily:   1,000 syncs/day  = $0.03/day
Hourly:  24,000 syncs/day = $0.84/day  (28x more expensive!)
```

### 2. 🚦 Rate Limiting
```
Flow blockchain limits:
→ Too many syncs = throttled
→ Transactions fail
→ Users affected
```

### 3. ⏱️ Time Delays
```
Each sync takes ~5 seconds
Sync 10,000 users = 14 hours sequentially!
```

### 4. 🔥 Server Load
```
Must sign every transaction
Database writes for every sync
Error handling overhead
```

### 5. 📉 Diminishing Returns
```
User earns 10 GUM → Synced
User earns 15 GUM → Synced
User earns 20 GUM → Synced
User never transfers → All syncs wasted! 😢
```

---

## ✅ Best Strategy: Smart Sync

```typescript
Sync When:
├─ User reaches milestone (100, 500, 1000 GUM) ✅
├─ User about to transfer GUM ✅
├─ User about to claim drop ✅
└─ Daily cron (only if balance changed) ✅

DON'T Sync When:
├─ User just earns daily login ❌
├─ User browses website ❌
├─ Balance unchanged ❌
└─ User inactive ❌
```

### Cost Savings Example:

```
10,000 Users:

Daily All Users:
→ 10,000 syncs/day
→ $11/month
→ Many wasted syncs

Smart Sync:
→ 100 syncs/day (only active)
→ $0.50/month
→ 96% cheaper! 🎉
```

---

## 🎯 Recommended Config

```typescript
const SYNC_CONFIG = {
  // Only sync at big milestones
  milestones: [100, 500, 1000, 5000],
  
  // Always sync before blockchain actions
  beforeTransfer: true,
  beforeClaim: true,
  
  // Rate limit (max once per 24 hours)
  minInterval: 24 * 60 * 60 * 1000,
  
  // Daily backup (safety net)
  cron: 'once daily',
  cronOnlyChanged: true, // Skip unchanged
  
  // Skip small changes
  minChangeToSync: 10 // Only sync if +10 GUM
};
```

---

## 📈 Real Cost Comparison

### Your App with 10,000 Users:

```
Option A: Sync All Daily
─────────────────────────
10,000 users × 30 days = 300,000 syncs/month
Cost: $11/month
Waste: ~80% (inactive users)

Option B: Smart Sync (Recommended)
──────────────────────────────────
- 1,000 milestone syncs (10% reach milestone)
- 500 before-action syncs (5% transfer/claim)
- 2,000 cron syncs (20% changed)
Total: 3,500 syncs/month
Cost: $0.50/month
Savings: 96% cheaper! ✅

Option C: Lazy Sync (Cheapest)
───────────────────────────────
- Only sync users who transfer/claim
- ~500 syncs/month (5%)
Cost: $0.10/month
Savings: 99% cheaper! ✅✅
```

---

## 🏆 For Forte Hackathon

**Use Smart Sync!**

Shows you understand:
✅ Cost optimization  
✅ Scalability  
✅ Hybrid architecture  
✅ Production-ready thinking  

**Don't sync too often!**  
It's expensive and wasteful.

---

## 📝 Summary

| Question | Answer |
|----------|--------|
| **Is there a cost?** | Yes! ~$0.00003 per sync |
| **At scale?** | Can add up (daily all users = $11-100/month) |
| **Downside of frequent sync?** | 💰 Cost, 🚦 rate limits, ⏱️ delays, 📉 waste |
| **Best strategy?** | Smart sync (milestones + before actions) |
| **Cost savings?** | 80-99% cheaper than daily all users |
| **Recommended?** | Event-driven + daily backup |

**Bottom line:** Sync smartly, not frequently! 🎯

**Full details:** `docs/GUM-SYNC-COSTS.md`
