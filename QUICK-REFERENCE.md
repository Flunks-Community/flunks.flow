# GUMDrops Quick Reference

## 🎯 What Is It?
Airdrop & rewards system that gives users GUM tokens for daily engagement, time-based check-ins, and NFT ownership. **Works alongside your existing staking system.**

---

## 💰 Reward Amounts

| Type | Amount | Cooldown |
|------|--------|----------|
| Daily Check-in | 10 GUM + streak | 24 hours |
| AM Bonus | 5 GUM | 24 hours (6am-12pm UTC) |
| PM Bonus | 5 GUM | 24 hours (6pm-12am UTC) |
| Flunks Holder | 2 GUM per NFT | Anytime |
| Scheduled Drops | Custom | Admin-defined |

---

## 📝 Claim Commands

```bash
# Daily check-in (streak bonus!)
flow transactions send cadence/transactions/claim-daily-checkin.cdc --network testnet

# Morning bonus
flow transactions send cadence/transactions/claim-am-bonus.cdc --network testnet

# Evening bonus
flow transactions send cadence/transactions/claim-pm-bonus.cdc --network testnet

# NFT holder bonus
flow transactions send cadence/transactions/claim-flunks-holder-bonus.cdc --network testnet

# Scheduled drop
flow transactions send cadence/transactions/claim-scheduled-drop.cdc \
  --arg UInt64:0 \
  --network testnet
```

---

## 🔍 Check Eligibility

```bash
flow scripts execute cadence/scripts/check-gumdrop-eligibility.cdc \
  --arg Address:0xYOUR_ADDRESS \
  --network testnet
```

**Returns:**
```json
{
  "canClaimCheckIn": true,
  "canClaimAM": false,
  "canClaimPM": true,
  "currentStreak": 5,
  "totalGUMClaimed": 145.0,
  "flunksCount": 3
}
```

---

## 👑 Admin Commands

```bash
# Create a scheduled drop
flow transactions send cadence/transactions/admin-create-drop.cdc \
  --arg UFix64:1000.0 \    # Total pool
  --arg UFix64:10.0 \      # Per claim
  --arg UFix64:1728939600 \  # Start time (Unix)
  --arg UFix64:1729544400 \  # End time (Unix)
  --arg Bool:true \        # Requires Flunks?
  --network testnet
```

---

## 🚀 Integration with Your Code

### Frontend (React/Next.js Example)

```typescript
// Check what user can claim
const eligibility = await fcl.query({
  cadence: checkEligibilityScript,
  args: (arg, t) => [arg(userAddress, t.Address)]
});

// Show available claims
if (eligibility.canClaimCheckIn) {
  <Button onClick={claimCheckIn}>
    Claim {10 + eligibility.currentStreak} GUM
    (Streak: {eligibility.currentStreak})
  </Button>
}

if (eligibility.canClaimAM && eligibility.isAMHours) {
  <Button onClick={claimAM}>Claim AM Bonus (5 GUM)</Button>
}

if (eligibility.flunksCount > 0) {
  <Button onClick={claimFlunksBonus}>
    Claim {eligibility.flunksCount * 2} GUM
  </Button>
}
```

### Backend (Supabase Edge Function Example)

```typescript
// Optional: Track claims in database for analytics
export async function trackGUMClaim(claim: {
  user_address: string;
  claim_type: 'daily' | 'am' | 'pm' | 'flunks' | 'drop';
  amount: number;
  streak?: number;
}) {
  await supabase.from('gum_claims').insert({
    ...claim,
    claimed_at: new Date()
  });
}

// Optional: Send notifications when eligible
export async function checkAndNotify(userAddress: string) {
  const eligibility = await checkOnChainEligibility(userAddress);
  
  if (eligibility.canClaimCheckIn && eligibility.currentStreak >= 5) {
    await sendPushNotification(userAddress, {
      title: "Don't break your streak!",
      body: `Claim your ${10 + eligibility.currentStreak} GUM now!`
    });
  }
}
```

---

## 🏗️ File Structure

```
cadence/
├── contracts/
│   └── GUMDrops.cdc                    # Main contract
├── transactions/
│   ├── claim-daily-checkin.cdc         # User: Daily claim
│   ├── claim-am-bonus.cdc              # User: Morning bonus
│   ├── claim-pm-bonus.cdc              # User: Evening bonus
│   ├── claim-flunks-holder-bonus.cdc   # User: NFT bonus
│   ├── claim-scheduled-drop.cdc        # User: Event drop
│   └── admin-create-drop.cdc           # Admin: Create drop
└── scripts/
    └── check-gumdrop-eligibility.cdc   # Check claims

docs/
├── GUMDROPS-GUIDE.md                   # Full documentation
└── FLOW-ACTIONS-INTEGRATION.md         # Hackathon guide
```

---

## ⚡ Quick Deploy

```bash
# 1. Deploy contract
flow accounts add-contract GUMDrops ./cadence/contracts/GUMDrops.cdc --network testnet

# 2. Test a claim
flow transactions send ./cadence/transactions/claim-daily-checkin.cdc --network testnet

# 3. Check it worked
flow scripts execute ./cadence/scripts/check-gumdrop-eligibility.cdc \
  --arg Address:0xYOUR_ADDRESS \
  --network testnet
```

---

## 🐛 Troubleshooting

**"Cannot claim check-in yet"**
- Wait 24 hours since last claim
- Check `lastCheckInTime` in eligibility script

**"Cannot claim AM/PM bonus"**
- Must be during AM hours (6am-12pm UTC) or PM hours (6pm-12am UTC)
- Check `isAMHours` / `isPMHours` in eligibility script
- Wait 24 hours since last AM/PM claim

**"Must own at least one Flunks NFT"**
- User doesn't have Flunks in their collection
- Check `flunksCount` in eligibility script

**"Drop not found"**
- Invalid dropID
- Drop may have been removed by admin

**"Cannot claim from this drop"**
- Already claimed
- Drop not started yet
- Drop ended
- Out of funds
- Requires Flunks ownership

---

## 📊 Analytics Queries

```sql
-- Supabase: Track engagement
SELECT 
  claim_type,
  COUNT(*) as total_claims,
  SUM(amount) as total_gum,
  AVG(streak) as avg_streak
FROM gum_claims
WHERE claimed_at > NOW() - INTERVAL '30 days'
GROUP BY claim_type;

-- Top users by streak
SELECT 
  user_address,
  MAX(streak) as max_streak,
  COUNT(*) as check_ins
FROM gum_claims
WHERE claim_type = 'daily'
GROUP BY user_address
ORDER BY max_streak DESC
LIMIT 10;
```

---

## 🎮 Gamification Ideas

1. **Streak Leaderboard**: Show top streaks
2. **Achievement Badges**: Award NFTs for milestones
3. **Bonus Multipliers**: 2x GUM on weekends
4. **Referral Rewards**: Extra GUM for inviting friends
5. **Lucky Hours**: Random hourly bonuses
6. **Community Goals**: Unlock drops when milestones hit

---

## 📞 Support

- **Documentation**: `docs/GUMDROPS-GUIDE.md`
- **Flow Actions**: `docs/FLOW-ACTIONS-INTEGRATION.md`
- **Issues**: GitHub Issues
- **Discord**: [Your Discord]

---

## ✅ Pre-Launch Checklist

- [ ] Deploy GUMDrops.cdc to testnet
- [ ] Test all claim transactions
- [ ] Create test scheduled drops
- [ ] Verify eligibility script works
- [ ] Update contract addresses in scripts/transactions
- [ ] Test with multiple users
- [ ] Check streak logic (claim on consecutive days)
- [ ] Test AM/PM time windows
- [ ] Verify Flunks holder bonus
- [ ] Load test with many users
- [ ] Audit contract security
- [ ] Deploy to mainnet
- [ ] Update frontend
- [ ] Announce to community!

---

**Built for the Forte Hackathon 🚀**
