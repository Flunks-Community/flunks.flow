# ✅ GUM Auto-Sync - Quick Summary

## 🎯 Yes, Auto-Sync is Possible!

I've created **4 auto-sync strategies** for you. Here's the quick version:

---

## 🏆 Recommended: Hybrid Approach

**Combine 3 methods for best results:**

### 1. **Daily Cron Job** ⏰
```typescript
// Runs every night at midnight
// Syncs ALL users with updated balances
// Set it and forget it!

Schedule: 0 0 * * * (midnight daily)
File: app/api/cron/sync-gum-balances/route.ts
```

**When it runs:**
- Every day at midnight
- Syncs all users who earned GUM that day
- Background process, users don't notice

**Cost:** Low (once per day, batched)

---

### 2. **Event-Driven Sync** ⚡
```typescript
// Auto-syncs when user:
// - Reaches 100 GUM
// - Hits milestones (500, 1000, 5000)
// - Before transferring GUM
// - Before claiming drops

awardGum(user, 'daily_login') 
  → User reaches 100 GUM
  → Auto-syncs in background!
```

**When it runs:**
- User earns 100th GUM → auto-sync
- User about to transfer → auto-sync
- User about to claim drop → auto-sync

**Cost:** Low (only active users, when needed)

---

### 3. **Manual Sync Button** 🔘 (Optional)
```tsx
// Power users can force sync anytime
<SyncGumButton walletAddress={user.address} />

// "🔄 Sync to Blockchain" button
```

**When it runs:**
- User clicks button
- Once per hour max (rate limited)

**Cost:** Very Low (user-initiated only)

---

## 📁 Files Created

### Documentation
- ✅ `docs/GUM-AUTO-SYNC-STRATEGIES.md` - Complete guide with all 4 options

### Database Migration
- ✅ `supabase/migrations/add_gum_sync_tracking.sql` - Track sync history

---

## 🚀 How to Implement

### Step 1: Add Sync Tracking Table

Run the SQL migration:
```sql
-- Already created in: supabase/migrations/add_gum_sync_tracking.sql
CREATE TABLE gum_blockchain_syncs (...);
```

This tracks:
- When each user was last synced
- What balance was synced
- Transaction ID
- Sync type (cron, auto, manual)

---

### Step 2: Create Cron Job

**For Vercel:**
```json
// vercel.json
{
  "crons": [
    {
      "path": "/api/cron/sync-gum-balances",
      "schedule": "0 0 * * *"
    }
  ]
}
```

**For other platforms:**
```bash
# Use external cron service:
# - cron-job.org
# - EasyCron.com
# - GitHub Actions

# Add webhook to run daily
curl https://flunks.net/api/cron/sync-gum-balances \
  -H "Authorization: Bearer YOUR_SECRET"
```

---

### Step 3: Update GUM Earning Logic

```typescript
// In your existing awardGum() function
export async function awardGum(wallet: string, source: string) {
  // 1. Award GUM (your existing code)
  const result = await supabase.rpc('award_gum', { ... });
  
  // 2. Check if should auto-sync
  const { data: user } = await supabase
    .from('user_gum_balances')
    .select('total_gum')
    .eq('wallet_address', wallet)
    .single();
  
  // 3. Auto-sync at milestones
  const MILESTONES = [100, 500, 1000, 5000];
  if (MILESTONES.includes(user.total_gum)) {
    // Queue background sync
    await fetch('/api/jobs/sync-user', {
      method: 'POST',
      body: JSON.stringify({ 
        wallet, 
        balance: user.total_gum,
        syncType: 'milestone'
      })
    });
  }
  
  return result;
}
```

---

### Step 4: Auto-Sync Before Blockchain Actions

```typescript
// Before user transfers GUM
async function handleTransfer(to: string, amount: number) {
  // 1. Check if needs sync
  const needsSync = await checkIfNeedsSync(userWallet);
  
  if (needsSync) {
    // 2. Sync first
    await fetch('/api/user/sync-my-gum', {
      method: 'POST',
      body: JSON.stringify({ walletAddress: userWallet })
    });
    
    alert('✨ Synced latest balance to blockchain!');
  }
  
  // 3. Now transfer
  const txId = await transferGum(to, amount);
  alert('✅ Transfer successful!');
}
```

---

## 📊 Sync Frequency Examples

### Daily Cron (Option 1)
```
Day 1: User earns 40 GUM → Stays in Supabase
        ↓ (midnight)
Day 2: Cron syncs 40 GUM to blockchain ✅
       User earns 30 more → 70 total in Supabase
        ↓ (midnight)
Day 3: Cron syncs 70 GUM to blockchain ✅
```

### Event-Driven (Option 2)
```
User earns GUM:
  10 GUM → Supabase only
  20 GUM → Supabase only
  30 GUM → Supabase only
  ...
  100 GUM → ⚡ AUTO-SYNC to blockchain!
  
User clicks "Transfer":
  → ⚡ AUTO-SYNC latest balance
  → Then transfer on-chain
```

### Hybrid (Recommended)
```
Day 1-6: 
  User earns daily → Supabase
  (waits for cron)

Day 7:
  User reaches 100 GUM → ⚡ AUTO-SYNC
  (don't wait for cron!)

Day 7-14:
  User earns more → Supabase
  (waits for cron)

Day 14:
  User wants to transfer → ⚡ AUTO-SYNC
  Then transfer immediately
```

---

## 🎯 Benefits of Auto-Sync

### For Users:
✅ Don't need to think about syncing  
✅ Balance "just works" when needed  
✅ Can transfer/claim drops anytime  
✅ Always up-to-date on leaderboards  

### For You:
✅ Low gas costs (smart sync, not every action)  
✅ Scalable (batched daily sync)  
✅ Automated (cron handles it)  
✅ Flexible (multiple triggers)  

### For Forte Hackathon:
✅ Shows sophisticated architecture  
✅ Hybrid approach (Supabase + blockchain)  
✅ Smart automation  
✅ Production-ready system  

---

## 🔧 Technical Details

### Check if User Needs Sync

```typescript
async function checkIfNeedsSync(wallet: string): Promise<boolean> {
  // Get Supabase balance
  const { data: supabaseUser } = await supabase
    .from('user_gum_balances')
    .select('total_gum')
    .eq('wallet_address', wallet)
    .single();
  
  // Get last blockchain sync
  const { data: lastSync } = await supabase
    .from('gum_blockchain_syncs')
    .select('synced_balance')
    .eq('wallet_address', wallet)
    .order('synced_at', { ascending: false })
    .limit(1)
    .single();
  
  // Needs sync if balance increased
  return !lastSync || supabaseUser.total_gum > lastSync.synced_balance;
}
```

### Rate Limiting

```typescript
// Prevent spam syncs
const lastSync = await getLastSyncTime(wallet);
const hoursSince = (Date.now() - lastSync) / (1000 * 60 * 60);

if (hoursSince < 1) {
  throw new Error('Can only sync once per hour');
}
```

### Batch Processing

```typescript
// Sync 100 users at a time
const batchSize = 100;
for (let i = 0; i < users.length; i += batchSize) {
  const batch = users.slice(i, i + batchSize);
  
  for (const user of batch) {
    await syncUser(user);
  }
  
  await sleep(2000); // 2 sec between batches
}
```

---

## 📝 SQL Queries You Can Use

### Get users who need sync:
```sql
SELECT * FROM get_users_needing_sync();
```

### Check user's last sync:
```sql
SELECT * FROM latest_gum_syncs 
WHERE wallet_address = '0x123...';
```

### Sync stats:
```sql
SELECT 
  sync_type,
  COUNT(*) as total_syncs,
  AVG(synced_balance) as avg_balance
FROM gum_blockchain_syncs
WHERE synced_at > NOW() - INTERVAL '7 days'
GROUP BY sync_type;
```

---

## 🎉 Summary

**Yes, the contract CAN sync automatically!**

**Best approach:** Hybrid
1. ⏰ **Daily cron** - syncs everyone at midnight
2. ⚡ **Event-driven** - auto-syncs at milestones (100, 500, 1000)
3. ⚡ **Before actions** - auto-syncs before transfers/claims
4. 🔘 **Manual button** - power users can force sync

**Result:**
- ✅ Users rarely wait for sync
- ✅ Low gas costs
- ✅ Automated & scalable
- ✅ Great UX

**Read full guide:** `docs/GUM-AUTO-SYNC-STRATEGIES.md`

**Next step:** Choose your sync strategy and implement! 🚀
