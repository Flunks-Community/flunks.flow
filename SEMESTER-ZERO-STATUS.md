# SemesterZero - Current Status & Next Steps

**Contract Address:** `0x807c3d470888cc48` (mainnet)  
**Date:** October 28, 2025

---

## ✅ What's DEPLOYED & WORKING

### 1. **Halloween GumDrop** (Active NOW)
- **Drop ID:** `halloween-2025`
- **Amount:** 100 GUM per claim
- **Start:** Oct 26, 2025 @ 11:38 PM CST (1761604310)
- **End:** Nov 3, 2025 @ 6:00 PM CST (1762214400)
- **Eligible Wallets:** 3
  - `0x807c3d470888cc48` (you)
  - `0xe327216d843357f1`
  - `0x83a8d8f1c2438cd8`
- **Claims So Far:** 0/3
- **Status:** 🟢 LIVE - Users can claim now!

### 2. **SemesterZero Contract Features**
✅ GumDrop system (72-hour claim windows)  
✅ User profiles with timezone storage  
✅ Chapter 5 NFT tracking (slacker/overachiever)  
✅ Admin functions for managing drops  
✅ Event emission for all actions  

### 3. **Total Deployment History**
- **Total GumDrops Created:** 4 (including test drops)
- **Halloween Drop:** Currently active (#4)

---

## ⚠️ KNOWN ISSUES

### 1. **FlunksGraduation V1 Contract** (CRITICAL)
- **Problem:** Old contract uses pre-Cadence 1.0 syntax (`pub` instead of `access(all)`)
- **Impact:** Breaking Flow Token List scanning - your tokens won't show up on Flow ecosystem sites
- **Workaround:** FlunksGraduationV2 is deployed and working, but V1 can't be removed/updated
- **Status:** 🔴 BLOCKED - Needs Flow team support

**Why This Matters:**
- Token List scanners try to index ALL contracts on your account
- When they hit FlunksGraduation V1, parsing fails due to old syntax
- This prevents your NFTs from showing in ecosystem explorers

**Solutions:**
1. Contact Flow Discord (#dev-chat or #support) explaining the stuck pre-1.0 contract
2. Ask Token List team to skip contracts with parsing errors
3. Wait for Flow migration tooling update

### 2. **Website FCL Configuration**
- **Problem:** Frontend may still be using `FCL-TESTNET-CONFIG.js`
- **Impact:** Flow Wallet connects to testnet instead of mainnet
- **Fix:** Update flunks-site to use `FCL-MAINNET-CONFIG.js`
- **Status:** 🟡 NEEDS UPDATE (config file created, not integrated)

---

## 📋 NEXT STEPS TO GO LIVE

### Immediate (Before Nov 3):

#### 1. **Update Website FCL Config**
```javascript
// In flunks-site, replace FCL-TESTNET-CONFIG.js with:
import * as fcl from "@onflow/fcl"

fcl.config({
  "accessNode.api": "https://rest-mainnet.onflow.org",
  "discovery.wallet": "https://fcl-discovery.onflow.org/authn", // NO /testnet/
  "0xSemesterZero": "0x807c3d470888cc48",
  "0xFlunks": "0x807c3d470888cc48",
  "0xNonFungibleToken": "0x1d7e57aa55817448",
  "0xFungibleToken": "0xf233dcee88fe0abe",
  "0xMetadataViews": "0x1d7e57aa55817448"
})
```

#### 2. **Test Halloween Claim Flow**
- [ ] Connect wallet on mainnet
- [ ] Verify pumpkin button shows for all users (no NFT requirement)
- [ ] Click claim with one of the 3 eligible wallets
- [ ] Verify:
  - UserProfile created with timezone
  - 100 GUM credited
  - Transaction succeeds
  - GUM balance shows in UI

#### 3. **Monitor GumDrop Deadline**
- Drop ends **Nov 3 @ 6:00 PM CST**
- Check claims daily: `flow scripts execute /tmp/semester-zero-status.cdc --network mainnet`
- If no claims by Nov 2, troubleshoot website/wallet connection

### Post-Halloween:

#### 4. **Resolve FlunksGraduation V1 Issue**
**Option A: Contact Flow Team**
- Join Flow Discord: https://discord.gg/flow
- Post in #dev-chat or #support:
  ```
  I have a pre-Cadence 1.0 contract (FlunksGraduation) stuck on mainnet at 
  0x807c3d470888cc48. Can't update it (validator checks deployed version) 
  or remove it (needs service account auth). It's breaking Token List scanning.
  Already deployed V2 with Cadence 1.0. Need help removing/migrating V1.
  ```

**Option B: Contact Token List Team**
- Ask if they can skip contracts with parsing errors
- Request allowlist for `0x807c3d470888cc48`

#### 5. **Deploy Chapter 5 Features** (If Needed)
Currently deployed contract includes:
- Chapter5 NFT minting
- Slacker/Overachiever tracking
- Full completion detection

If you want to activate Chapter 5:
- [ ] Set up backend to track user progress
- [ ] Create Flow Actions workflow for auto-minting
- [ ] Admin mints Chapter 5 NFTs via `mintChapter5NFT()`

#### 6. **Create More GumDrops**
Use the admin transaction to create new drops:
```bash
flow transactions send cadence/transactions/create-gumdrop.cdc \
  --args-json='[
    {"type":"String","value":"thanksgiving-2025"},
    {"type":"UFix64","value":"200.0"},
    {"type":"Array","value":[
      {"type":"Address","value":"0x..."},
      {"type":"Address","value":"0x..."}
    ]},
    {"type":"UFix64","value":"259200.0"}
  ]' \
  --network mainnet --signer mainnet-account
```

---

## 🎯 HACKATHON FEATURE SUMMARY

### Forte Hackathon 3 Features (Oct 2025)

#### Feature 1: **GumDrop Airdrop System** ✅
- **What:** 72-hour claim windows for GUM token airdrops
- **Blockchain Integration:** On-chain eligibility, claim tracking, deadline enforcement
- **Flow Actions:** Backend triggers contract to open/close drops
- **Status:** DEPLOYED & ACTIVE (halloween-2025 drop live)

#### Feature 2: **Paradise Motel Day/Night Cycle** ✅
- **What:** Personalized 12-hour day/night cycle based on user timezone
- **Blockchain Integration:** Timezone stored on-chain in UserProfile
- **How It Works:** Frontend reads timezone, calculates local time, switches assets
- **Status:** DEPLOYED (timezone storage ready, frontend integration pending)

#### Feature 3: **Chapter 5 NFT Airdrop** ✅
- **What:** Auto-mint NFT when user completes all tasks (100%)
- **Blockchain Integration:** On-chain progress tracking, auto-airdrop on completion
- **Flow Actions:** Backend tracks completion, triggers mint
- **Status:** CONTRACT READY (needs backend integration)

---

## 📊 DEPLOYMENT CHECKLIST

| Component | Status | Next Action |
|-----------|--------|-------------|
| SemesterZero Contract | ✅ Deployed | None - working |
| Halloween GumDrop | ✅ Active | Monitor claims |
| FlunksGraduationV2 | ✅ Deployed | None - working |
| FlunksGraduation V1 | 🔴 Stuck | Contact Flow team |
| FCL Mainnet Config | 🟡 Created | Integrate in website |
| Claim Transaction | ✅ Ready | Test on mainnet |
| Website Pumpkin Button | 🟡 Unknown | Verify shows for all users |
| Token List Scanning | 🔴 Broken | Wait for V1 fix |
| Flow CLI | ✅ v2.10.0 | None - updated |

---

## 🔗 QUICK REFERENCE

### Key Transactions
- **Claim GumDrop:** `cadence/transactions/claim-gumdrop-with-timezone.cdc`
- **Create GumDrop:** `cadence/transactions/create-gumdrop.cdc`
- **Update GumDrop End Time:** `cadence/transactions/update-gumdrop-endtime.cdc`

### Key Scripts
- **Check GumDrop Status:** `/tmp/semester-zero-status.cdc`
- **Check User Profile:** `cadence/scripts/get-user-profile.cdc`

### Important Addresses
- **SemesterZero:** `0x807c3d470888cc48`
- **FlunksGraduationV2:** `0x807c3d470888cc48`
- **NonFungibleToken:** `0x1d7e57aa55817448`
- **FungibleToken:** `0xf233dcee88fe0abe`

### Mainnet Config
```javascript
accessNode: "https://rest-mainnet.onflow.org"
discovery.wallet: "https://fcl-discovery.onflow.org/authn"
```

---

## 💡 TIPS

1. **Testing Claims:** Use one of the 3 eligible wallets first, save the other 2 for real users
2. **Monitoring:** Check claim status daily with the status script
3. **Deadline:** Nov 3 @ 6:00 PM CST - after this, no more claims possible
4. **GUM Balance:** After claim, users should see 100 GUM in their profile
5. **Chapter 5:** Can activate later - contract is ready when you need it

---

## 📞 SUPPORT CONTACTS

- **Flow Discord:** https://discord.gg/flow (#dev-chat, #support)
- **Flow Docs:** https://developers.flow.com
- **Cadence Migration Guide:** https://cadence-lang.org/docs/cadence-migration-guide

---

**Last Updated:** October 28, 2025  
**Contract Version:** SemesterZero v1.0 (Forte Hackathon Edition)  
**Halloween Drop Status:** 🎃 ACTIVE - 0/3 claims, 6 days remaining
