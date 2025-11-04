# Chapter 5 NFT Airdrop System
**Status**: ✅ Contract functions ready | ⏳ Backend integration needed

---

## 📋 Completion Criteria

### Slacker Objective (Required)
- User enters `SLACKER` code
- Stored in `access_code_discoveries` table with `success = true`

### Overachiever Objective (Required)
- User completes Hidden Riff Challenge
- User enters `CGAF` code  
- Stored in `access_code_discoveries` table with `success = true`

### NFT Eligibility
- ✅ BOTH codes entered successfully
- ✅ Chapter5Collection setup in user's account
- ❌ NFT not already airdropped

---

## 🏗️ What's Already Built

### Smart Contract (SemesterZero_Hackathon.cdc)
```cadence
// Mark objectives complete
access(Admin) fun registerSlackerCompletion(userAddress: Address)
access(Admin) fun registerOverachieverCompletion(userAddress: Address)

// Check and airdrop
access(Admin) fun airdropChapter5NFT(userAddress: Address)
access(all) fun isEligibleForChapter5NFT(userAddress: Address): Bool
access(all) fun getChapter5Status(userAddress: Address): Chapter5Status

// Stats
access(all) fun getStats(): {String: UInt64} // totalChapter5Completions, totalChapter5NFTs
```

### Cadence Transactions
- ✅ `register-slacker-completion.cdc`
- ✅ `register-overachiever-completion.cdc`  
- ✅ `airdrop-chapter5-nft.cdc`

### Supabase SQL Function
```sql
SELECT * FROM get_chapter5_completions();
-- Returns: wallet_address, slacker_entered_at, cgaf_entered_at
```

---

## ⏳ What's Missing

### 1. Backend Integration
**File**: `chapter5-airdrop-integration.ts`

Options:
- **A) Webhook**: Trigger on new `access_code_discoveries` entries (realtime)
- **B) Cron Job**: Check for completions every hour
- **C) Manual**: Run bulk airdrop script after Halloween window

### 2. Collection Setup Check
Users must have `Chapter5Collection` initialized. They get this automatically when they:
- Claim a GumDrop with timezone (`claim-gumdrop-with-timezone.cdc`)
- Visit Paradise Motel page (creates UserProfile)

---

## 🚀 Deployment Options

### Option A: Realtime Webhooks (Recommended)
```typescript
// Supabase webhook → Next.js API route
// File: pages/api/chapter5-webhook.ts

export default async function handler(req, res) {
  const { wallet_address, code_entered } = req.body
  
  if (code_entered === 'SLACKER') {
    await syncObjectiveToBlockchain(wallet_address, 'slacker')
  } else if (code_entered === 'CGAF') {
    await syncObjectiveToBlockchain(wallet_address, 'overachiever')
  }
  
  // Check if BOTH complete → auto-airdrop NFT
  const completion = await checkChapter5Completion(wallet_address)
  if (completion.fullyComplete) {
    await checkAndAirdropChapter5NFT(wallet_address)
  }
  
  res.status(200).json({ success: true })
}
```

**Setup**: Add Supabase webhook pointing to your API route

---

### Option B: Cron Job (Background Sync)
```bash
# Run every hour to sync completions
0 * * * * /path/to/sync-chapter5-completions.sh
```

**Pro**: Less infrastructure  
**Con**: Delay between code entry and NFT airdrop

---

### Option C: Manual Bulk Airdrop (Safest)
```bash
# After Halloween window closes (Nov 3)
./bulk-chapter5-airdrop.sh
```

**Pro**: Full control, verify everything first  
**Con**: Manual process

---

## 📊 Query Eligible Wallets

### SQL (Supabase)
```sql
SELECT * FROM get_chapter5_completions();
```

### Cadence Script
```cadence
import SemesterZero from 0x807c3d470888cc48

access(all) fun main(userAddress: Address): Chapter5Status {
  return SemesterZero.getChapter5Status(userAddress: userAddress)
}
```

Returns:
```typescript
{
  slackerComplete: true,
  overachieverComplete: true,
  nftAirdropped: false,
  completionTimestamp: 1730500000
}
```

---

## 🎯 Testing Workflow

### 1. Test Single User
```bash
# Register Slacker
flow transactions send \
  ./cadence/transactions/register-slacker-completion.cdc \
  0x1234... \
  --network=mainnet \
  --signer=mainnet-account

# Register Overachiever  
flow transactions send \
  ./cadence/transactions/register-overachiever-completion.cdc \
  0x1234... \
  --network=mainnet \
  --signer=mainnet-account

# Check eligibility
flow scripts execute ./cadence/scripts/check-chapter5-eligibility.cdc 0x1234...

# Airdrop NFT
flow transactions send \
  ./cadence/transactions/airdrop-chapter5-nft.cdc \
  0x1234... \
  --network=mainnet \
  --signer=mainnet-account
```

---

## 🔄 Timeline

### Oct 31 - Nov 3: Halloween Window
- Users discover Paradise Motel
- Users enter SLACKER code
- Users complete Hidden Riff → get CGAF code

### Nov 3+: Bulk Airdrop
```bash
# 1. Deploy SQL function to Supabase
psql < supabase/migrations/20250125_chapter5_completions.sql

# 2. Get eligible wallets
SELECT * FROM get_chapter5_completions();

# 3. Run bulk airdrop
./bulk-chapter5-airdrop.sh
```

---

## 🛠️ Admin Commands

### Check Total Stats
```bash
flow scripts execute <<'EOF'
import SemesterZero from 0x807c3d470888cc48

access(all) fun main(): {String: UInt64} {
  return SemesterZero.getStats()
}
EOF
```

Returns: `{ totalChapter5Completions: 42, totalChapter5NFTs: 38 }`

### Check Individual User
```bash
flow scripts execute ./cadence/scripts/get-chapter5-status.cdc 0x1234...
```

---

## ❓ FAQ

**Q: What if user completes objectives but doesn't have Chapter5Collection?**  
A: They'll appear in Supabase results but airdrop will fail. Script shows warning. They need to claim a GumDrop first.

**Q: Can users claim multiple Chapter 5 NFTs?**  
A: No. Contract checks `nftAirdropped` flag. Once airdropped, they're permanently ineligible.

**Q: What happens if bulk airdrop script fails mid-run?**  
A: Safe to re-run. Contract checks eligibility for each wallet. Already-airdropped users will be skipped.

**Q: Do we need to register BOTH objectives separately?**  
A: Yes. Frontend should call `registerSlackerCompletion()` when SLACKER code entered, then `registerOverachieverCompletion()` when CGAF code entered.

---

## 📁 Files Created

- ✅ `chapter5-airdrop-integration.ts` - Backend sync logic
- ✅ `supabase/migrations/20250125_chapter5_completions.sql` - SQL function
- ✅ `bulk-chapter5-airdrop.sh` - Manual bulk airdrop script
- ✅ `CHAPTER5-AIRDROP-GUIDE.md` - This guide

**Next Step**: Choose integration approach (webhook vs cron vs manual)
