# 🎃 Halloween Airdrop - Quick Reference

## TL;DR - Fast Setup

```bash
# 1. Make script executable
chmod +x halloween-airdrop.sh

# 2. Create Halloween drop
./halloween-airdrop.sh create

# 3. Check drop status
./halloween-airdrop.sh check

# 4. Users claim on website (see guide)
```

---

## Two Ways to Airdrop GUM

### 🎯 Option 1: Special Drop (Recommended for Halloween)
**Users claim it themselves = More engaging!**

✅ Create time-limited Halloween event  
✅ Users visit website and click "Claim"  
✅ Automatic tracking of who claimed  
✅ Can require Flunks ownership  
✅ Creates FOMO and engagement  

**Perfect for:** Public Halloween event, community engagement

### 💉 Option 2: Direct Batch Airdrop
**You push GUM directly = No user action needed**

✅ Admin pushes GUM to addresses  
✅ Guaranteed delivery  
✅ No claiming required  
✅ Good for rewarding specific users  

**Perfect for:** Rewarding contributors, specific user groups

---

## Files Created

### Transactions
- `cadence/transactions/halloween-create-drop.cdc` - Admin creates drop
- `cadence/transactions/halloween-claim-drop.cdc` - Users claim drop
- `cadence/transactions/halloween-batch-airdrop.cdc` - Admin batch airdrop

### Scripts
- `cadence/scripts/check-halloween-drop.cdc` - View all active drops
- `cadence/scripts/check-user-drop-eligibility.cdc` - Check if user can claim

### Tools
- `halloween-airdrop.sh` - Automated helper script
- `HALLOWEEN-AIRDROP-GUIDE.md` - Complete documentation

---

## Quick Commands

```bash
# Create drop with defaults
flow transactions send cadence/transactions/halloween-create-drop.cdc \
  --arg String:"🎃 Halloween Treat" \
  --arg String:"Spooky GUM for Flunks holders!" \
  --arg UFix64:100.0 \
  --arg UFix64:1729296000.0 \
  --arg UFix64:1730419199.0 \
  --arg Bool:true \
  --arg Int:1 \
  --arg UInt64:1000 \
  --network testnet \
  --signer admin

# Check drops
flow scripts execute cadence/scripts/check-halloween-drop.cdc --network testnet

# User claims (on website)
flow transactions send cadence/transactions/halloween-claim-drop.cdc \
  --arg UInt64:1 \
  --network testnet \
  --signer user
```

---

## Website Integration Snippet

```javascript
// Check active drops
const drops = await fcl.query({
  cadence: `
    import SemesterZero from 0xYOUR_ADDRESS
    access(all) fun main(): [SemesterZero.SpecialDropInfo] {
      return SemesterZero.getActiveDrops()
    }
  `
});

// User claims drop
const txId = await fcl.mutate({
  cadence: CLAIM_TRANSACTION_CODE,
  args: (arg, t) => [arg(dropID, t.UInt64)]
});
```

---

## Parameters Cheatsheet

**Drop Creation:**
- `name`: "🎃 Halloween Treat 2025"
- `description`: "Spooky message..."
- `amount`: `100.0` (GUM per claim)
- `startTime`: `1729296000.0` (Oct 18, 2025)
- `endTime`: `1730419199.0` (Oct 31, 2025)
- `requiredFlunks`: `true` (must own Flunks)
- `minFlunksCount`: `1` (at least 1 Flunks)
- `maxClaims`: `1000` (max claimers)

---

## Flow Events to Monitor

```cadence
// When drop is created
event SpecialDropCreated(dropID: UInt64, name: String, startTime: UFix64, endTime: UFix64)

// When user claims
event SpecialDropClaimed(dropID: UInt64, claimer: Address, amount: UFix64)

// When GUM is synced
event GumSynced(owner: Address, oldBalance: UFix64, newBalance: UFix64)
```

---

## Next Steps

1. ✅ **Deploy SemesterZero.cdc** (if not deployed)
2. ✅ **Create Halloween drop** using transaction
3. ✅ **Add claim button** to website
4. ✅ **Monitor claims** via events
5. ✅ **Promote** on social media! 🎃

---

## Support

Need help? Check `HALLOWEEN-AIRDROP-GUIDE.md` for detailed instructions.

Contract: `cadence/contracts/SemesterZero.cdc`
