# Update Website FCL Config - Mainnet Switch

## What This Does

**Current State:** Your website connects to Flow TESTNET  
**After Update:** Your website connects to Flow MAINNET  

This allows users to:
- ✅ See their real Flunks NFTs
- ✅ Claim real Halloween GumDrop (100 GUM)
- ✅ Interact with real contracts at `0x807c3d470888cc48`

---

## The Problem Explained

When users visit your site and click "Connect Wallet", the FCL (Flow Client Library) config tells Flow Wallet **which network** to connect to:

```javascript
// WRONG (testnet):
"discovery.wallet": "https://fcl-discovery.onflow.org/testnet/authn"
// Flow Wallet connects to TESTNET (fake tokens, test contracts)

// CORRECT (mainnet):
"discovery.wallet": "https://fcl-discovery.onflow.org/authn"
// Flow Wallet connects to MAINNET (real tokens, real contracts)
```

The `/testnet/` in the URL is what's causing the issue!

---

## Step-by-Step Fix

### 1. Find Your Website FCL Config

Look for where you initialize FCL in your flunks-site project. Common locations:

```
flunks-site/
  src/
    config/fcl.js          ← Common
    lib/flow.js            ← Common
    utils/fcl-config.js    ← Common
    App.js                 ← Sometimes here
    flow/config.js         ← Common
```

Search for files containing:
```javascript
fcl.config({
  "accessNode.api":
  "discovery.wallet":
```

### 2. Replace TESTNET Config with MAINNET Config

**BEFORE (Testnet - WRONG):**
```javascript
import * as fcl from "@onflow/fcl";

fcl.config({
  "app.detail.title": "Flunks",
  "app.detail.icon": "https://flunks.io/logo.png",
  "accessNode.api": "https://rest-testnet.onflow.org",           // ❌ TESTNET
  "discovery.wallet": "https://fcl-discovery.onflow.org/testnet/authn", // ❌ TESTNET
  "0xSemesterZero": "0xb97ea2274b0ae5d2",                        // ❌ Testnet address
  "0xFlunks": "0xb97ea2274b0ae5d2",                             // ❌ Testnet address
  "0xNonFungibleToken": "0x631e88ae7f1d7c20",                    // ❌ Testnet address
  "flow.network": "testnet"                                      // ❌ TESTNET
});
```

**AFTER (Mainnet - CORRECT):**
```javascript
import * as fcl from "@onflow/fcl";

fcl.config({
  "app.detail.title": "Flunks",
  "app.detail.icon": "https://flunks.io/logo.png",
  "accessNode.api": "https://rest-mainnet.onflow.org",           // ✅ MAINNET
  "discovery.wallet": "https://fcl-discovery.onflow.org/authn",  // ✅ MAINNET (no /testnet/)
  "0xSemesterZero": "0x807c3d470888cc48",                        // ✅ Mainnet address
  "0xFlunks": "0x807c3d470888cc48",                             // ✅ Mainnet address
  "0xNonFungibleToken": "0x1d7e57aa55817448",                    // ✅ Mainnet address
  "0xFungibleToken": "0xf233dcee88fe0abe",                      // ✅ Mainnet address
  "0xMetadataViews": "0x1d7e57aa55817448",                       // ✅ Mainnet address
  "flow.network": "mainnet"                                      // ✅ MAINNET
});
```

### 3. Update Any Hardcoded Addresses in Scripts/Transactions

If you have Cadence scripts embedded in your frontend, update imports:

**BEFORE:**
```javascript
const script = `
  import SemesterZero from 0xb97ea2274b0ae5d2  // ❌ Testnet
  import Flunks from 0xb97ea2274b0ae5d2        // ❌ Testnet
  
  access(all) fun main(user: Address): Bool {
    return SemesterZero.activeGumDrop != nil
  }
`;
```

**AFTER:**
```javascript
const script = `
  import SemesterZero from 0x807c3d470888cc48  // ✅ Mainnet
  import Flunks from 0x807c3d470888cc48        // ✅ Mainnet
  
  access(all) fun main(user: Address): Bool {
    return SemesterZero.activeGumDrop != nil
  }
`;
```

### 4. Test the Connection

After updating:

1. **Clear browser cache** (important!)
2. **Restart dev server**
3. **Visit your site**
4. **Click "Connect Wallet"**
5. **Verify Flow Wallet shows MAINNET** (look for mainnet indicator in wallet UI)
6. **Check your address** - should start with `0x` and have mainnet Flow balance

---

## Complete Mainnet Config Reference

Copy this entire config if you need it:

```javascript
import * as fcl from "@onflow/fcl";

fcl.config({
  // App details (shows in wallet connect dialog)
  "app.detail.title": "Flunks",
  "app.detail.icon": "https://flunks.io/logo.png",
  
  // Network configuration
  "accessNode.api": "https://rest-mainnet.onflow.org",
  "discovery.wallet": "https://fcl-discovery.onflow.org/authn",
  "flow.network": "mainnet",
  
  // Contract addresses - Your contracts
  "0xSemesterZero": "0x807c3d470888cc48",
  "0xFlunks": "0x807c3d470888cc48",
  "0xFlunksGraduationV2": "0x807c3d470888cc48",
  "0xHybridCustodyHelper": "0x807c3d470888cc48",
  
  // Contract addresses - Flow core contracts (mainnet)
  "0xNonFungibleToken": "0x1d7e57aa55817448",
  "0xFungibleToken": "0xf233dcee88fe0abe",
  "0xMetadataViews": "0x1d7e57aa55817448",
  "0xViewResolver": "0x1d7e57aa55817448",
  "0xFlowToken": "0x1654653399040a61"
});
```

---

## Verification Checklist

After updating, verify these work:

- [ ] Flow Wallet connects to **mainnet** (not testnet)
- [ ] User can see their mainnet Flow balance
- [ ] Pumpkin button appears on site
- [ ] Clicking claim opens Flow Wallet with transaction
- [ ] Transaction shows contract `0x807c3d470888cc48`
- [ ] After approval, GumDrop claim succeeds
- [ ] User receives 100 GUM (check profile)

---

## Common Issues

### Issue: "Account not found" error
**Cause:** User doesn't have account on mainnet or wrong network  
**Fix:** User needs to create mainnet account in Flow Wallet

### Issue: Wallet still shows testnet
**Cause:** Browser cache or config not loaded  
**Fix:** Hard refresh (Cmd+Shift+R), clear cache, restart dev server

### Issue: Transaction fails with "contract not found"
**Cause:** Still using testnet addresses in scripts  
**Fix:** Search codebase for `0xb97ea2274b0ae5d2` and replace with `0x807c3d470888cc48`

### Issue: No GUM balance after claim
**Cause:** Transaction went to testnet contract  
**Fix:** Verify FCL config is mainnet, check transaction on Flowscan

---

## Quick Test Commands

Check if GumDrop is active (should work after config update):

```javascript
// In browser console on your site
fcl.config().get("accessNode.api")
// Should return: "https://rest-mainnet.onflow.org"

fcl.config().get("0xSemesterZero")
// Should return: "0x807c3d470888cc48"
```

---

## Halloween GumDrop Status

Once mainnet config is live:

- **Drop ID:** `halloween-2025`
- **Amount:** 100 GUM per claim
- **Deadline:** Nov 3, 2025 @ 6:00 PM CST
- **Eligible:** 3 wallets (including yours)
- **Claims:** 0/3 so far

Make sure to test claim ASAP to verify everything works before users try!

---

## Reference Files

I've created two reference configs in this repo:

- `FCL-TESTNET-CONFIG.js` - Testnet config (for development)
- `FCL-MAINNET-CONFIG.js` - Mainnet config (for production) ← USE THIS ONE

You can copy/paste from `FCL-MAINNET-CONFIG.js` into your flunks-site FCL config file.

---

**Last Updated:** October 28, 2025  
**Halloween Drop Status:** 🎃 ACTIVE - 0/3 claims, 6 days remaining
