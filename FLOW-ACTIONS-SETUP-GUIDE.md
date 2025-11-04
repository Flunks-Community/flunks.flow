# Flow Actions Setup for Halloween GumDrop

## Overview
Flow Actions allows you to schedule blockchain transactions to execute automatically at specific times. We'll use this to activate the Halloween GumDrop at exactly 12:01 AM on October 31, 2025.

## What We Need to Schedule

**Transaction:** `start-halloween-drop-mainnet.cdc`
**Action:** Call `FlunksGumDrop.Admin.startDrop()`
**Trigger Time:** October 31, 2025 at 12:01 AM EST (Unix: `1730347260`)

**Transaction Arguments:**
```
startTime: 1730347260.0   // Oct 31, 12:01 AM EST
endTime: 1730606460.0     // Nov 3, 12:01 AM EST (72 hours later)
gumPerFlunk: 100          // 100 GUM per claim
```

## Setup Steps

### Option 1: Flow Actions Dashboard (Recommended)
1. Visit the Flow Actions dashboard (check Forte/Flow docs for URL)
2. Connect your admin wallet: `0x807c3d470888cc48`
3. Click "Create New Action"
4. Configure:
   - **Transaction File:** Upload `start-halloween-drop-mainnet.cdc`
   - **Network:** Mainnet
   - **Trigger Time:** 2025-10-31 00:01:00 EST (Unix: 1730347260)
   - **Signer:** mainnet-account
   - **Arguments:**
     - `startTime`: `1730347260.0` (UFix64)
     - `endTime`: `1730606460.0` (UFix64)
     - `gumPerFlunk`: `100` (UInt64)
5. Review and confirm
6. Action will execute automatically at scheduled time!

### Option 2: Flow CLI (If Supported)
```bash
# Check if Flow CLI has actions command
flow actions --help

# If available, create scheduled action
flow actions create \
  --transaction cadence/transactions/start-halloween-drop-mainnet.cdc \
  --network mainnet \
  --signer mainnet-account \
  --trigger-time 1730347260 \
  --args-json '[
    {"type":"UFix64","value":"1730347260.0"},
    {"type":"UFix64","value":"1730606460.0"},
    {"type":"UInt64","value":"100"}
  ]'
```

### Option 3: Vercel Cron Job (Backup)
If Flow Actions isn't available yet, use Vercel Serverless Functions:

**File:** `flunks-site/pages/api/cron/start-halloween-drop.ts`
```typescript
// Deploy to Vercel with cron schedule in vercel.json:
// "crons": [{"path": "/api/cron/start-halloween-drop", "schedule": "1 0 31 10 *"}]

export default async function handler(req, res) {
  // Check if it's the right time (Oct 31, 12:01 AM EST)
  const now = new Date();
  if (now.getTime() < 1730347260000) {
    return res.status(200).json({ message: 'Not time yet' });
  }
  
  // Submit transaction to Flow blockchain
  const fcl = require('@onflow/fcl');
  // ... configure FCL and submit transaction
  
  return res.status(200).json({ success: true });
}
```

## Verification

After scheduling, you can verify:

1. **Before Oct 31:** Visit flunks.net/myLocker
   - Should see: "No active GumDrop at this time"
   - Button: Hidden ❌

2. **After 12:01 AM Oct 31:** Refresh the page
   - Should see: "🎃 HALLOWEEN GUMDROP" with countdown
   - Button: "🎃 Claim 100 GUM" ✅

3. **After Nov 3:** Drop automatically closes
   - Should see: "No active GumDrop" again
   - Button: Hidden ❌

## Manual Trigger (Fallback)

If Flow Actions fails or you need to trigger manually:

```bash
cd /Users/jeremy/Desktop/flunks.flow

flow transactions send cadence/transactions/start-halloween-drop-mainnet.cdc \
  1730347260.0 \
  1730606460.0 \
  100 \
  --network mainnet \
  --signer mainnet-account \
  --gas-limit 1000
```

## Contract Details

- **Contract:** FlunksGumDrop
- **Address:** 0x807c3d470888cc48
- **Network:** Mainnet
- **Admin Path:** /storage/FlunksGumDropAdmin

## Next Steps

1. ✅ Contract deployed
2. ✅ Frontend updated
3. ⏳ Schedule Flow Action (DO THIS NOW)
4. ⏳ Test on Oct 31 at 12:01 AM
5. ⏳ Monitor during 72-hour window
6. ✅ Drop auto-closes after Nov 3 at 12:01 AM

🎃 **Happy Halloween!**
