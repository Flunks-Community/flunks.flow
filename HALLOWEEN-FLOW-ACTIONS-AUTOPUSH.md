# 🎃 Halloween Airdrop with Flow Actions Auto-Push

## Overview

Use **Flow Actions** (Forte upgrade) to create a scheduled Halloween airdrop that automatically pushes from Supabase to user wallets!

---

## 🎯 What This Enables

### Traditional Approach (Manual)
```
1. Admin creates drop on-chain ❌ Manual
2. Users claim on website ❌ Requires action
3. Admin syncs Supabase → Blockchain ❌ Manual batch job
```

### Flow Actions Approach (Automated) ⭐
```
1. Supabase webhook triggers on Halloween 🎃
2. Flow Actions Source pulls from Supabase balance
3. Flow Actions Sink deposits to user wallets
4. All automated via scheduled cron job! ✅
```

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────┐
│              SUPABASE (GUM Database)                 │
│  ─────────────────────────────────────              │
│  Users earn GUM all month (daily locker, etc.)      │
│  Halloween: Everyone has 100+ GUM earned            │
└────────────────┬────────────────────────────────────┘
                 │
                 │ Scheduled Job (Oct 31, 2025)
                 ↓
┌─────────────────────────────────────────────────────┐
│         FLOW ACTIONS WORKFLOW (Automated)            │
│  ─────────────────────────────────────              │
│  For each eligible user:                            │
│    1. SupabaseGumSource.withdrawAvailable()         │
│    2. HalloweenBonusSink.deposit()                  │
│    3. SemesterZero.GumAccount updated               │
└─────────────────┬───────────────────────────────────┘
                  │
                  ↓
┌─────────────────────────────────────────────────────┐
│         USER WALLETS (Blockchain)                    │
│  ─────────────────────────────────                  │
│  🎃 Halloween bonus appears automatically!          │
│  🎃 No user action required                         │
│  🎃 Fully on-chain, composable with transfers       │
└─────────────────────────────────────────────────────┘
```

---

## 🔧 Implementation

### Step 1: Add Flow Actions to SemesterZero

Add this to `SemesterZero.cdc`:

```cadence
import DeFiActions from 0xDEFIACTIONS_ADDRESS

/// Flow Actions Source: Pull GUM from Supabase balance
access(all) struct SupabaseGumSource: DeFiActions.Source, DeFiActions.IdentifiableStruct {
    access(all) let userAddress: Address
    access(all) let supabaseBalance: UFix64
    access(all) let uniqueID: {DeFiActions.UniqueIdentifier}?
    
    init(
        userAddress: Address,
        supabaseBalance: UFix64,
        uniqueID: {DeFiActions.UniqueIdentifier}?
    ) {
        self.userAddress = userAddress
        self.supabaseBalance = supabaseBalance
        self.uniqueID = uniqueID
    }
    
    access(all) view fun getSourceType(): Type {
        return Type<@{FungibleToken.Vault}>()
    }
    
    /// Returns the Supabase balance available to push
    access(all) fun minimumAvailable(): UFix64 {
        return self.supabaseBalance
    }
    
    /// Simulates "withdrawing" from Supabase
    /// In reality, this represents Supabase balance being pushed to blockchain
    access(FungibleToken.Withdraw) fun withdrawAvailable(maxAmount: UFix64): @{FungibleToken.Vault} {
        let amount = self.supabaseBalance < maxAmount ? self.supabaseBalance : maxAmount
        
        // Create a reference to represent this Supabase balance
        // The actual sync happens via Admin.syncUserBalance separately
        
        // For Flow Actions, we return a "virtual" vault
        // that represents the Supabase balance being moved
        
        // This is a marker that tells the workflow how much GUM to sync
        return <- SemesterZero.createVirtualGumVault(amount: amount)
    }
    
    access(all) view fun id(): UInt64 {
        return self.uniqueID?.id ?? 0
    }
}

/// Flow Actions Sink: Deposit GUM to user's on-chain account
access(all) struct GumAccountSink: DeFiActions.Sink, DeFiActions.IdentifiableStruct {
    access(all) let recipient: Address
    access(all) let uniqueID: {DeFiActions.UniqueIdentifier}?
    
    init(recipient: Address, uniqueID: {DeFiActions.UniqueIdentifier}?) {
        self.recipient = recipient
        self.uniqueID = uniqueID
    }
    
    access(all) view fun getSinkType(): Type {
        return Type<@{FungibleToken.Vault}>()
    }
    
    access(all) fun minimumCapacity(): UFix64 {
        // Unlimited capacity (can always deposit GUM)
        return UFix64.max
    }
    
    access(all) fun depositCapacity(from: auth(FungibleToken.Withdraw) &{FungibleToken.Vault}) {
        let amount = from.balance
        
        // Get recipient's GUM account
        let account = getAccount(self.recipient)
        let gumAccountRef = account.capabilities
            .get<&GumAccount>(SemesterZero.GumAccountPublicPath)
            .borrow()
            ?? panic("Recipient doesn't have GUM account")
        
        // Deposit the amount
        gumAccountRef.deposit(amount: amount)
        
        // Destroy the virtual vault
        destroy from
    }
    
    access(all) view fun id(): UInt64 {
        return self.uniqueID?.id ?? 0
    }
}

/// Helper: Create virtual GUM vault for Flow Actions
access(all) fun createVirtualGumVault(amount: UFix64): @VirtualGumVault {
    return <- create VirtualGumVault(balance: amount)
}

/// Virtual vault that represents Supabase GUM being moved
access(all) resource VirtualGumVault: FungibleToken.Vault {
    access(all) var balance: UFix64
    
    init(balance: UFix64) {
        self.balance = balance
    }
    
    access(FungibleToken.Withdraw) fun withdraw(amount: UFix64): @{FungibleToken.Vault} {
        self.balance = self.balance - amount
        return <- create VirtualGumVault(balance: amount)
    }
    
    access(all) fun deposit(from: @{FungibleToken.Vault}) {
        let vault <- from as! @VirtualGumVault
        self.balance = self.balance + vault.balance
        destroy vault
    }
    
    access(all) fun createEmptyVault(): @{FungibleToken.Vault} {
        return <- create VirtualGumVault(balance: 0.0)
    }
    
    access(all) view fun isAvailableToWithdraw(amount: UFix64): Bool {
        return self.balance >= amount
    }
    
    access(all) view fun getViews(): [Type] {
        return []
    }
    
    access(all) fun resolveView(_ view: Type): AnyStruct? {
        return nil
    }
}
```

---

### Step 2: Create Autopush Transaction

Create `cadence/transactions/halloween-autopush-user.cdc`:

```cadence
import SemesterZero from "../contracts/SemesterZero.cdc"
import DeFiActions from 0xDEFIACTIONS_ADDRESS

/// Automated Halloween airdrop using Flow Actions
/// Pushes Supabase GUM balance to user's on-chain account
///
/// Called by admin for each eligible user

transaction(
    userAddress: Address,
    supabaseBalance: UFix64,
    halloweenBonus: UFix64
) {
    
    prepare(admin: auth(Storage, BorrowValue) &Account) {
        // Calculate total (existing balance + Halloween bonus)
        let totalAmount = supabaseBalance + halloweenBonus
        
        // Create unique identifier for tracing
        let uniqueID = DeFiActions.createUniqueIdentifier()
        
        // 1. Create Source (Supabase balance)
        let source = SemesterZero.SupabaseGumSource(
            userAddress: userAddress,
            supabaseBalance: totalAmount,
            uniqueID: uniqueID
        )
        
        // 2. Create Sink (user's on-chain GumAccount)
        let sink = SemesterZero.GumAccountSink(
            recipient: userAddress,
            uniqueID: uniqueID
        )
        
        // 3. Execute Flow Actions workflow
        let virtualVault <- source.withdrawAvailable(maxAmount: totalAmount)
        sink.depositCapacity(from: &virtualVault as auth(FungibleToken.Withdraw) &{FungibleToken.Vault})
        
        // Clean up
        destroy virtualVault
        
        log("🎃 Halloween autopush complete for ".concat(userAddress.toString()))
        log("   Supabase: ".concat(supabaseBalance.toString()))
        log("   Bonus: ".concat(halloweenBonus.toString()))
        log("   Total: ".concat(totalAmount.toString()))
    }
}
```

---

### Step 3: Create Supabase Autopush API

Create `app/api/halloween/autopush/route.ts`:

```typescript
import { createClient } from '@supabase/supabase-js';
import * as fcl from '@onflow/fcl';

// Vercel Cron or scheduled job
export async function POST(req: Request) {
  // Verify this is called by cron (security)
  const authHeader = req.headers.get('authorization');
  if (authHeader !== `Bearer ${process.env.CRON_SECRET}`) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 });
  }
  
  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
  );
  
  console.log('🎃 Starting Halloween autopush...');
  
  // 1. Get all eligible users (must have Flunks)
  const { data: users, error } = await supabase
    .from('user_gum_balances')
    .select('wallet_address, total_gum')
    .gte('total_gum', 50) // Must have earned at least 50 GUM
    .order('total_gum', { ascending: false });
  
  if (error || !users) {
    return Response.json({ error: 'Failed to fetch users' }, { status: 500 });
  }
  
  const HALLOWEEN_BONUS = 100.0; // 100 GUM bonus per user
  const results = { success: 0, failed: 0, errors: [] as any[] };
  
  // 2. Process each user
  for (const user of users) {
    try {
      // Check if user has Flunks (on-chain verification)
      const hasFlunks = await checkUserHasFlunks(user.wallet_address);
      
      if (!hasFlunks) {
        console.log(`⏭️  Skip ${user.wallet_address} - no Flunks`);
        continue;
      }
      
      // Execute Flow Actions autopush transaction
      const txId = await fcl.mutate({
        cadence: HALLOWEEN_AUTOPUSH_TRANSACTION,
        args: (arg, t) => [
          arg(user.wallet_address, t.Address),
          arg(user.total_gum.toFixed(8), t.UFix64),
          arg(HALLOWEEN_BONUS.toFixed(8), t.UFix64)
        ],
        authorizations: [adminAuthorizationFunction],
        limit: 9999
      });
      
      await fcl.tx(txId).onceSealed();
      
      // Record the autopush in database
      await supabase.from('halloween_autopush_log').insert({
        wallet_address: user.wallet_address,
        supabase_balance: user.total_gum,
        bonus_amount: HALLOWEEN_BONUS,
        total_pushed: user.total_gum + HALLOWEEN_BONUS,
        tx_id: txId,
        pushed_at: new Date().toISOString()
      });
      
      results.success++;
      console.log(`✅ Pushed ${user.total_gum + HALLOWEEN_BONUS} GUM to ${user.wallet_address}`);
      
    } catch (error) {
      results.failed++;
      results.errors.push({
        wallet: user.wallet_address,
        error: error.message
      });
      console.error(`❌ Failed ${user.wallet_address}:`, error);
    }
    
    // Rate limiting: wait 2 seconds between users
    await new Promise(resolve => setTimeout(resolve, 2000));
  }
  
  console.log('🎃 Halloween autopush complete!');
  console.log(`   Success: ${results.success}`);
  console.log(`   Failed: ${results.failed}`);
  
  return Response.json(results);
}

// Helper: Check if user owns Flunks NFTs
async function checkUserHasFlunks(address: string): Promise<boolean> {
  try {
    const result = await fcl.query({
      cadence: `
        import NonFungibleToken from 0x1d7e57aa55817448
        
        access(all) fun main(address: Address): Int {
          let account = getAccount(address)
          let collection = account.capabilities
            .get<&{NonFungibleToken.CollectionPublic}>(/public/FlunksCollection)
            .borrow()
          
          return collection?.getIDs().length ?? 0
        }
      `,
      args: (arg, t) => [arg(address, t.Address)]
    });
    
    return result > 0;
  } catch {
    return false;
  }
}

const HALLOWEEN_AUTOPUSH_TRANSACTION = `
  import SemesterZero from 0xYOUR_ADDRESS
  import DeFiActions from 0xDEFIACTIONS_ADDRESS
  
  transaction(userAddress: Address, supabaseBalance: UFix64, halloweenBonus: UFix64) {
    prepare(admin: auth(Storage, BorrowValue) &Account) {
      let totalAmount = supabaseBalance + halloweenBonus
      let uniqueID = DeFiActions.createUniqueIdentifier()
      
      let source = SemesterZero.SupabaseGumSource(
        userAddress: userAddress,
        supabaseBalance: totalAmount,
        uniqueID: uniqueID
      )
      
      let sink = SemesterZero.GumAccountSink(
        recipient: userAddress,
        uniqueID: uniqueID
      )
      
      let virtualVault <- source.withdrawAvailable(maxAmount: totalAmount)
      sink.depositCapacity(from: &virtualVault as auth(FungibleToken.Withdraw) &{FungibleToken.Vault})
      destroy virtualVault
    }
  }
`;

function adminAuthorizationFunction(account: any) {
  return {
    ...account,
    tempId: `${process.env.ADMIN_ADDRESS}-${account.keyId}`,
    addr: fcl.sansPrefix(process.env.ADMIN_ADDRESS),
    keyId: Number(process.env.ADMIN_KEY_ID),
    signingFunction: async (signable: any) => {
      // Use your admin key to sign
      return {
        addr: fcl.withPrefix(process.env.ADMIN_ADDRESS),
        keyId: Number(process.env.ADMIN_KEY_ID),
        signature: await signWithAdminKey(signable.message)
      };
    }
  };
}
```

---

### Step 4: Schedule with Vercel Cron

Add to `vercel.json`:

```json
{
  "crons": [
    {
      "path": "/api/halloween/autopush",
      "schedule": "0 0 31 10 *"
    }
  ]
}
```

This runs at **midnight UTC on October 31st** (Halloween)!

---

## 🚀 How It Works

### The Flow

1. **October 1-30**: Users earn GUM in Supabase (daily locker, activities)
2. **October 31, 12:00 AM UTC**: Vercel Cron triggers `/api/halloween/autopush`
3. **For each eligible user**:
   - Check Flunks ownership (must own at least 1)
   - Get Supabase balance
   - Add 100 GUM Halloween bonus
   - Execute Flow Actions workflow:
     - `SupabaseGumSource` → pulls total from Supabase
     - `GumAccountSink` → deposits to on-chain GumAccount
4. **Result**: All Flunks holders wake up to GUM in their blockchain wallets! 🎃

---

## ✅ Benefits of Flow Actions Approach

### vs. Manual Airdrop
- ✅ **Automated**: No manual admin work
- ✅ **Scheduled**: Runs at exact Halloween moment
- ✅ **Composable**: Can add more steps (swap, stake, etc.)
- ✅ **Traceable**: UniqueIdentifier tracks entire workflow
- ✅ **Safe**: Atomic transactions (all or nothing)

### vs. SpecialDrop
- ✅ **No user action needed**: Appears automatically
- ✅ **Surprise factor**: "Whoa, GUM appeared!"
- ✅ **Better UX**: No claiming, just wake up to rewards
- ✅ **Combines Supabase + Bonus**: One transaction

---

## 🎯 Advanced: Multi-Step Autopush

You can even auto-stake or auto-swap the airdrop:

```cadence
transaction(userAddress: Address, supabaseBalance: UFix64, bonus: UFix64) {
  prepare(admin: auth(Storage, BorrowValue) &Account) {
    let uniqueID = DeFiActions.createUniqueIdentifier()
    
    // 1. Source: Supabase GUM
    let source = SemesterZero.SupabaseGumSource(...)
    
    // 2. Swapper: 50% GUM → FLOW
    let swapper = IncrementFiSwapConnectors.Swapper(
      path: ["GUM", "FlowToken"],
      inVault: Type<@VirtualGumVault>(),
      outVault: Type<@FlowToken.Vault>(),
      uniqueID: uniqueID
    )
    
    // 3. Sink: Deposit FLOW to user
    let flowSink = FungibleTokenConnectors.VaultSink(...)
    
    // Execute: Supabase → 50% GUM (keep) + 50% FLOW (swap)
    let vault <- source.withdrawAvailable(maxAmount: total)
    let halfAmount = vault.balance / 2.0
    
    let gumVault <- vault.withdraw(amount: halfAmount)
    let flowVault <- swapper.swap(quote: nil, inVault: <- vault)
    
    // Deposit both
    gumSink.depositCapacity(from: &gumVault)
    flowSink.depositCapacity(from: &flowVault)
    
    destroy gumVault
    destroy flowVault
  }
}
```

Now users get **50% GUM + 50% FLOW** automatically! 🔥

---

## 📊 Monitoring

### Check Autopush Status

```typescript
// Query Supabase for autopush results
const { data } = await supabase
  .from('halloween_autopush_log')
  .select('*')
  .order('pushed_at', { ascending: false });

console.log(`Total pushed: ${data.length}`);
console.log(`Total GUM distributed: ${data.reduce((sum, r) => sum + r.total_pushed, 0)}`);
```

### Query Flow Events

```bash
# Check Flow Actions events
flow events get A.XXX.DeFiActions.SourceWithdrawn \
  --start HALLOWEEN_BLOCK \
  --end HALLOWEEN_BLOCK+1000

flow events get A.XXX.DeFiActions.SinkDeposited \
  --start HALLOWEEN_BLOCK \
  --end HALLOWEEN_BLOCK+1000
```

---

## 🎃 Complete Setup Checklist

- [ ] Add Flow Actions interfaces to `SemesterZero.cdc`
- [ ] Create `SupabaseGumSource` struct
- [ ] Create `GumAccountSink` struct
- [ ] Create `VirtualGumVault` resource
- [ ] Deploy updated `SemesterZero.cdc` to testnet
- [ ] Create `/api/halloween/autopush/route.ts`
- [ ] Add cron schedule to `vercel.json`
- [ ] Test with single user first
- [ ] Create `halloween_autopush_log` table in Supabase
- [ ] Set environment variables (CRON_SECRET, ADMIN keys)
- [ ] Schedule for October 31, 2025 00:00 UTC
- [ ] Monitor execution on Halloween! 🎃

---

## 🚨 Important Notes

1. **Admin pays gas**: Each user push = 1 transaction
2. **Rate limiting**: Wait 2 seconds between users
3. **Batch processing**: If >1000 users, split into batches
4. **Error handling**: Log failures, retry later
5. **Dry run first**: Test on testnet with test data

---

## 🎯 Summary

**Flow Actions** lets you:
- ✅ **Schedule** Halloween airdrop for exact time
- ✅ **Autopush** Supabase balances + bonus to wallets
- ✅ **Compose** with swaps, stakes, other DeFi actions
- ✅ **Trace** entire workflow with UniqueIdentifier
- ✅ **Surprise** users with automatic rewards! 🎃

This is **next-level airdrop tech** - users don't claim, the GUM just appears!

Ready to implement? Start with Step 1 above! 👻
