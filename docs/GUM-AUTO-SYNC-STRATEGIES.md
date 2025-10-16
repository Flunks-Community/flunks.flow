# GUM Auto-Sync Strategies

## 🔄 Automatic Synchronization Options

There are **4 ways** to automatically sync Supabase balances to the blockchain:

---

## Option 1: Scheduled Cron Job (Recommended ⭐)

Sync all balances on a schedule (daily, weekly, etc.)

### Implementation

```typescript
// app/api/cron/sync-gum-balances/route.ts
import { createClient } from '@supabase/supabase-js';
import * as fcl from '@onflow/fcl';

export async function GET(req: Request) {
  // Verify cron secret (security)
  const authHeader = req.headers.get('authorization');
  if (authHeader !== `Bearer ${process.env.CRON_SECRET}`) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 });
  }
  
  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
  );
  
  // 1. Get all users with updated balances since last sync
  const { data: users, error } = await supabase
    .from('user_gum_balances')
    .select('wallet_address, total_gum, updated_at')
    .order('updated_at', { ascending: false });
  
  if (error) {
    return Response.json({ error: error.message }, { status: 500 });
  }
  
  // 2. Batch sync to blockchain (max 100 at a time to avoid timeouts)
  const batchSize = 100;
  const results = {
    synced: 0,
    failed: 0,
    skipped: 0,
    errors: []
  };
  
  for (let i = 0; i < users.length; i += batchSize) {
    const batch = users.slice(i, i + batchSize);
    
    for (const user of batch) {
      try {
        // Check if user has GUM account on-chain first
        const hasAccount = await checkGumAccountExists(user.wallet_address);
        
        if (!hasAccount) {
          results.skipped++;
          console.log(`Skipped ${user.wallet_address} - no on-chain account`);
          continue;
        }
        
        // Sync balance to blockchain
        const txId = await syncUserBalance(user.wallet_address, user.total_gum);
        
        // Record sync in database
        await supabase.from('gum_blockchain_syncs').insert({
          wallet_address: user.wallet_address,
          synced_balance: user.total_gum,
          tx_id: txId,
          synced_at: new Date().toISOString(),
          status: 'completed'
        });
        
        results.synced++;
        console.log(`✅ Synced ${user.wallet_address}: ${user.total_gum} GUM`);
        
      } catch (error) {
        results.failed++;
        results.errors.push({
          wallet: user.wallet_address,
          error: error.message
        });
        console.error(`❌ Failed ${user.wallet_address}:`, error);
      }
    }
    
    // Sleep between batches to avoid rate limits
    if (i + batchSize < users.length) {
      await sleep(2000); // 2 second delay
    }
  }
  
  return Response.json({
    success: true,
    timestamp: new Date().toISOString(),
    results: results
  });
}

// Helper: Check if user has GumAccount on-chain
async function checkGumAccountExists(address: string): Promise<boolean> {
  try {
    const result = await fcl.query({
      cadence: `
        import GumDropsHybrid from 0xYOUR_ADDRESS
        
        access(all) fun main(address: Address): Bool {
          let account = getAccount(address)
          
          if let cap = account.capabilities.get<&GumDropsHybrid.GumAccount>(
            GumDropsHybrid.GumAccountPublicPath
          ).borrow() {
            return true
          }
          
          return false
        }
      `,
      args: (arg, t) => [arg(address, t.Address)]
    });
    
    return result;
  } catch {
    return false;
  }
}

// Helper: Sync single user balance
async function syncUserBalance(address: string, balance: number): Promise<string> {
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
      arg(address, t.Address),
      arg(balance.toFixed(8), t.UFix64)
    ],
    authorizations: [fcl.authz], // Admin authorization
    limit: 1000
  });
  
  await fcl.tx(txId).onceSealed();
  return txId;
}

function sleep(ms: number) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
```

### Setup Cron Job

**Vercel:**
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

**Or use external cron service:**
```bash
# Add to crontab or use services like:
# - EasyCron.com
# - cron-job.org
# - GitHub Actions

# Daily at midnight
curl -X GET https://flunks.net/api/cron/sync-gum-balances \
  -H "Authorization: Bearer YOUR_CRON_SECRET"
```

### Pros & Cons

✅ **Pros:**
- Predictable (runs on schedule)
- Batch processing (efficient)
- Low server load (off-peak hours)
- Easy to monitor

❌ **Cons:**
- Not real-time (users wait for next sync)
- Could fail if many users (timeout)

**Best for:** Daily/weekly syncs for all users

---

## Option 2: User-Triggered Sync (On-Demand)

Users sync their own balance when they need to transfer or claim drops.

### Implementation

```typescript
// app/api/user/sync-my-gum/route.ts
export async function POST(req: Request) {
  const { walletAddress } = await req.json();
  
  // Rate limiting (prevent spam)
  const lastSync = await getLastSyncTime(walletAddress);
  const hoursSinceSync = (Date.now() - lastSync) / (1000 * 60 * 60);
  
  if (hoursSinceSync < 1) {
    return Response.json({
      error: 'Can only sync once per hour',
      nextSyncAvailable: new Date(lastSync + 60 * 60 * 1000).toISOString()
    }, { status: 429 });
  }
  
  // Get current Supabase balance
  const { data: user } = await supabase
    .from('user_gum_balances')
    .select('total_gum')
    .eq('wallet_address', walletAddress)
    .single();
  
  if (!user) {
    return Response.json({ error: 'User not found' }, { status: 404 });
  }
  
  // Sync to blockchain
  try {
    const txId = await syncUserBalance(walletAddress, user.total_gum);
    
    return Response.json({
      success: true,
      txId: txId,
      syncedBalance: user.total_gum,
      message: `Synced ${user.total_gum} GUM to blockchain!`
    });
  } catch (error) {
    return Response.json({
      error: error.message
    }, { status: 500 });
  }
}
```

### Frontend Component

```tsx
// components/SyncGumButton.tsx
'use client';

import { useState } from 'react';

export function SyncGumButton({ walletAddress }: { walletAddress: string }) {
  const [syncing, setSyncing] = useState(false);
  const [lastSync, setLastSync] = useState<Date | null>(null);
  
  const handleSync = async () => {
    setSyncing(true);
    
    try {
      const res = await fetch('/api/user/sync-my-gum', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ walletAddress })
      });
      
      const data = await res.json();
      
      if (data.success) {
        alert(`✅ Synced ${data.syncedBalance} GUM to blockchain!`);
        setLastSync(new Date());
      } else {
        alert(`❌ ${data.error}`);
      }
    } catch (error) {
      alert('Sync failed');
    } finally {
      setSyncing(false);
    }
  };
  
  return (
    <button
      onClick={handleSync}
      disabled={syncing}
      className="sync-btn"
    >
      {syncing ? '⏳ Syncing...' : '🔄 Sync to Blockchain'}
    </button>
  );
}
```

### Pros & Cons

✅ **Pros:**
- User controls when to sync
- Only syncs active users (saves gas)
- On-demand (sync before transfer)

❌ **Cons:**
- Users must manually sync
- Extra step for users
- Could forget to sync

**Best for:** Users who want to transfer or claim drops

---

## Option 3: Event-Driven Sync (Smart ⭐⭐)

Automatically sync when user reaches milestones or before blockchain actions.

### Implementation

```typescript
// lib/gum/autoSync.ts

// Auto-sync triggers:
const SYNC_TRIGGERS = {
  BALANCE_THRESHOLD: 100,    // Sync when balance > 100 GUM
  BEFORE_TRANSFER: true,     // Sync before on-chain transfer
  BEFORE_CLAIM: true,        // Sync before claiming drop
  MILESTONE: [100, 500, 1000] // Sync at milestones
};

// Hook into GUM earning
export async function awardGumWithAutoSync(
  walletAddress: string,
  source: string,
  metadata: any
) {
  // Award GUM in Supabase
  const result = await awardGum(walletAddress, source, metadata);
  
  if (!result.success) return result;
  
  // Get new balance
  const { data: user } = await supabase
    .from('user_gum_balances')
    .select('total_gum')
    .eq('wallet_address', walletAddress)
    .single();
  
  const newBalance = user.total_gum;
  
  // Check if should auto-sync
  const shouldSync = 
    newBalance >= SYNC_TRIGGERS.BALANCE_THRESHOLD ||
    SYNC_TRIGGERS.MILESTONE.includes(newBalance);
  
  if (shouldSync) {
    // Sync in background (don't block user)
    syncInBackground(walletAddress, newBalance);
  }
  
  return result;
}

// Background sync (non-blocking)
async function syncInBackground(address: string, balance: number) {
  try {
    // Queue sync job
    await fetch('/api/jobs/sync-user', {
      method: 'POST',
      body: JSON.stringify({ address, balance })
    });
  } catch (error) {
    console.error('Background sync failed:', error);
  }
}

// Before blockchain actions
export async function prepareForBlockchainAction(walletAddress: string) {
  // Check if balance needs sync
  const { data: user } = await supabase
    .from('user_gum_balances')
    .select('total_gum, updated_at')
    .eq('wallet_address', walletAddress)
    .single();
  
  // Check last on-chain sync
  const { data: lastSync } = await supabase
    .from('gum_blockchain_syncs')
    .select('synced_balance, synced_at')
    .eq('wallet_address', walletAddress)
    .order('synced_at', { ascending: false })
    .limit(1)
    .single();
  
  const needsSync = 
    !lastSync ||
    lastSync.synced_balance < user.total_gum;
  
  if (needsSync) {
    // Sync now (blocking - user waits)
    await syncUserBalance(walletAddress, user.total_gum);
    return {
      synced: true,
      balance: user.total_gum
    };
  }
  
  return {
    synced: false,
    balance: lastSync.synced_balance
  };
}
```

### Usage in Transfer Flow

```typescript
// When user initiates transfer
async function handleTransferGum(to: string, amount: number) {
  // 1. Auto-sync if needed
  const syncResult = await prepareForBlockchainAction(userAddress);
  
  if (syncResult.synced) {
    alert('✨ Synced your latest GUM balance to blockchain!');
  }
  
  // 2. Now proceed with transfer
  const txId = await fcl.mutate({
    cadence: transferGumCadence,
    args: (arg, t) => [
      arg(to, t.Address),
      arg(amount.toFixed(8), t.UFix64),
      arg(message, t.Optional(t.String))
    ],
    authorizations: [fcl.currentUser]
  });
  
  alert(`Transfer successful! TX: ${txId}`);
}
```

### Pros & Cons

✅ **Pros:**
- Automatic (no user action needed)
- Smart (only when necessary)
- Seamless UX
- Saves gas (only active users)

❌ **Cons:**
- More complex logic
- Requires job queue
- Could delay user actions slightly

**Best for:** Production apps with good UX

---

## Option 4: Real-Time Sync (Expensive ⚠️)

Sync every time balance changes (not recommended).

### Implementation

```typescript
// Supabase Database Webhook
// Configure in Supabase Dashboard: Database > Webhooks

// Create webhook function
create function sync_gum_to_blockchain()
returns trigger as $$
begin
  -- Call your API to sync
  perform net.http_post(
    url := 'https://flunks.net/api/webhooks/gum-updated',
    body := json_build_object(
      'wallet_address', NEW.wallet_address,
      'total_gum', NEW.total_gum
    )::text
  );
  return NEW;
end;
$$ language plpgsql;

-- Create trigger
create trigger gum_balance_updated
  after insert or update on user_gum_balances
  for each row
  execute function sync_gum_to_blockchain();
```

```typescript
// app/api/webhooks/gum-updated/route.ts
export async function POST(req: Request) {
  const { wallet_address, total_gum } = await req.json();
  
  // Sync to blockchain immediately
  await syncUserBalance(wallet_address, total_gum);
  
  return Response.json({ success: true });
}
```

### Pros & Cons

✅ **Pros:**
- Always synced
- Real-time

❌ **Cons:**
- **Very expensive** (gas for every earn)
- Slow (blockchain delay on every action)
- Could overwhelm Flow network
- Not practical

**Not recommended** - Use Option 1, 2, or 3 instead!

---

## 📊 Comparison Table

| Strategy | Frequency | Cost | UX | Complexity | Best For |
|----------|-----------|------|----|-----------:|----------|
| **Cron Job** | Daily/Weekly | Low | Good | ⭐ Easy | Passive users |
| **User-Triggered** | On-demand | Very Low | Manual | ⭐ Easy | Power users |
| **Event-Driven** | Smart | Low | Seamless | ⭐⭐⭐ Medium | Production |
| **Real-Time** | Every change | 💰💰💰 High | Slow | ⭐⭐ Medium | ❌ Don't use |

---

## 🏆 Recommended Strategy: Hybrid Approach

**Combine Option 1 + Option 3:**

1. **Daily Cron Job** (Option 1)
   - Syncs all users at midnight
   - Catches everyone eventually
   - Runs during low traffic

2. **Event-Driven** (Option 3)
   - Auto-syncs when user hits 100 GUM
   - Auto-syncs before transfers/claims
   - Auto-syncs at milestones (500, 1000)

3. **User Button** (Optional)
   - "Sync Now" button for power users
   - Manual override if needed

### Implementation

```typescript
// config/gumSync.ts
export const GUM_SYNC_CONFIG = {
  // Daily cron
  cronSchedule: '0 0 * * *', // Midnight daily
  
  // Event triggers
  autoSyncThreshold: 100,  // Auto-sync at 100 GUM
  autoSyncMilestones: [500, 1000, 5000, 10000],
  autoSyncBeforeTransfer: true,
  autoSyncBeforeClaim: true,
  
  // Rate limiting
  minSyncInterval: 60 * 60 * 1000, // 1 hour between syncs
  
  // Batch settings
  batchSize: 100,
  batchDelay: 2000 // 2 seconds
};
```

```typescript
// Daily cron: syncs everyone
GET /api/cron/sync-gum-balances
→ Runs at midnight
→ Syncs all updated balances

// Event-driven: smart sync
awardGum(user, 'daily_login', {...})
→ User reaches 100 GUM
→ Auto-syncs in background

// Before blockchain action: ensure sync
userClicksTransfer()
→ prepareForBlockchainAction(user)
→ Syncs if needed
→ Proceeds with transfer
```

---

## 🚀 Quick Start: Implementing Auto-Sync

### Step 1: Add Tracking Table

```sql
-- Track blockchain syncs
CREATE TABLE gum_blockchain_syncs (
  id SERIAL PRIMARY KEY,
  wallet_address VARCHAR(64) NOT NULL,
  synced_balance BIGINT NOT NULL,
  tx_id VARCHAR(128),
  synced_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  status VARCHAR(32) DEFAULT 'completed',
  sync_type VARCHAR(32) DEFAULT 'manual' -- 'cron', 'auto', 'manual'
);

CREATE INDEX idx_syncs_wallet ON gum_blockchain_syncs(wallet_address);
CREATE INDEX idx_syncs_date ON gum_blockchain_syncs(synced_at);
```

### Step 2: Create Cron Job

Create `app/api/cron/sync-gum-balances/route.ts` (see Option 1 above)

### Step 3: Setup Cron Schedule

**Vercel:**
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

### Step 4: Add Event-Driven Sync

Update your `awardGum()` function to check thresholds and auto-sync

### Step 5: Add User Sync Button (Optional)

Add `<SyncGumButton />` component to user dashboard

---

## 🎯 Summary

**Auto-sync is definitely possible!** Here's what I recommend:

✅ **Daily Cron Job** - Syncs all users at midnight  
✅ **Event-Driven** - Auto-syncs at milestones (100, 500, 1000 GUM)  
✅ **Before Transfers** - Auto-syncs before blockchain actions  
✅ **Manual Button** - Let power users force sync  

This hybrid approach gives you:
- 📅 Predictable syncs (daily cron)
- 🎯 Smart syncs (milestones, before actions)
- 💰 Low cost (only when needed)
- ✨ Great UX (mostly invisible to users)

**The blockchain will stay in sync automatically!** 🚀
