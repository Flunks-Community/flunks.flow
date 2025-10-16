# GUMDrops - Flow Actions Based Airdrop System

## Overview

**GUMDrops** is a Flow Actions-compliant airdrop and reward distribution system for the Flunks ecosystem. It **complements** your existing staking system by adding:

- ✅ **Daily Check-In Rewards** with streak bonuses
- ✅ **Time-Based Bonuses** (AM/PM rewards)
- ✅ **Token-Gated Rewards** (Flunks holder bonuses)
- ✅ **Scheduled Airdrops** with customizable parameters
- ✅ **No conflicts** with your existing Supabase/Staking setup

---

## How It Works With Your Existing System

### Your Current Setup (KEEP AS IS!)
```
Staking.cdc → NFT staking rewards (time-based GUM accumulation)
GUM.cdc → Your fungible token
GUMStakingTracker.cdc → Tracks staking claims
```

### New GUMDrops System (ADDS NEW FEATURES!)
```
GUMDrops.cdc → Separate reward pools for different activities
  - Daily check-ins (login rewards)
  - AM/PM bonuses (time-of-day engagement)
  - Flunks holder bonuses (NFT ownership rewards)
  - Scheduled drops (event-based airdrops)
```

**Key Point**: These are SEPARATE reward mechanisms. Users can:
- ✅ Claim staking rewards from Staking.cdc
- ✅ ALSO claim daily check-ins from GUMDrops.cdc
- ✅ ALSO claim time bonuses from GUMDrops.cdc
- ✅ Everything works together!

---

## Reward Structure

### 1. Daily Check-In Rewards
```cadence
Base Reward: 10 GUM
Streak Bonus: +1 GUM per consecutive day
Example: 5-day streak = 10 + 5 = 15 GUM
```

**How it works:**
- Users can claim once every 24 hours
- Consecutive daily claims build a streak
- Missing a day resets the streak to 1
- Perfect for daily engagement!

### 2. AM Bonus (6am - 12pm UTC)
```cadence
Bonus: 5 GUM
Frequency: Once per day during morning hours
```

**How it works:**
- Only claimable during 6am-12pm UTC
- Separate from daily check-in
- Encourages morning engagement

### 3. PM Bonus (6pm - 12am UTC)
```cadence
Bonus: 5 GUM
Frequency: Once per day during evening hours
```

**How it works:**
- Only claimable during 6pm-12am UTC
- Separate from daily check-in and AM bonus
- Encourages evening engagement

### 4. Flunks Holder Bonus
```cadence
Bonus: 2 GUM per Flunks NFT owned
Example: Own 5 Flunks = 10 GUM bonus
```

**How it works:**
- Token-gated (requires Flunks NFT ownership)
- Scales with number of Flunks owned
- Great for rewarding collectors

### 5. Scheduled Drops (Admin-Created)
```cadence
Customizable:
- Total amount pool
- Amount per claim
- Start/end times
- Flunks-gated or open
```

**How it works:**
- Admins create time-limited drops
- First-come-first-served (until pool depletes)
- Can require Flunks ownership
- Perfect for events, milestones, announcements

---

## Transaction Files

### For Users

#### `claim-daily-checkin.cdc`
```bash
# Claim daily check-in with streak bonus
flow transactions send cadence/transactions/claim-daily-checkin.cdc
```

#### `claim-am-bonus.cdc`
```bash
# Claim AM bonus (only works 6am-12pm UTC)
flow transactions send cadence/transactions/claim-am-bonus.cdc
```

#### `claim-pm-bonus.cdc`
```bash
# Claim PM bonus (only works 6pm-12am UTC)
flow transactions send cadence/transactions/claim-pm-bonus.cdc
```

#### `claim-flunks-holder-bonus.cdc`
```bash
# Claim bonus based on Flunks owned
flow transactions send cadence/transactions/claim-flunks-holder-bonus.cdc
```

#### `claim-scheduled-drop.cdc`
```bash
# Claim from a specific scheduled drop
flow transactions send cadence/transactions/claim-scheduled-drop.cdc --arg UInt64:0
```

### For Admins

#### `admin-create-drop.cdc`
```bash
# Create a scheduled drop
# Example: 1000 GUM total, 10 GUM per claim, starts now, ends in 7 days, requires Flunks
flow transactions send cadence/transactions/admin-create-drop.cdc \
  --arg UFix64:1000.0 \
  --arg UFix64:10.0 \
  --arg UFix64:$(date +%s) \
  --arg UFix64:$(date -v+7d +%s) \
  --arg Bool:true
```

---

## Script Files

### `check-gumdrop-eligibility.cdc`
Check a user's claim history and current eligibility:

```bash
flow scripts execute cadence/scripts/check-gumdrop-eligibility.cdc --arg Address:0x...
```

**Returns:**
```json
{
  "hasData": true,
  "lastCheckInTime": 1728939600,
  "currentStreak": 5,
  "totalCheckIns": 12,
  "totalGUMClaimed": 145.0,
  "canClaimCheckIn": false,
  "canClaimAM": true,
  "canClaimPM": false,
  "isAMHours": true,
  "isPMHours": false,
  "flunksCount": 3
}
```

---

## Integration with Supabase (Optional)

Your existing Supabase setup can be **enhanced** with GUMDrops:

### Current Supabase Logic (Keep!)
```javascript
// Your existing staking claims
- Track NFT stake/unstake
- Calculate staking rewards
- Claim staking GUM
```

### Add GUMDrops Integration
```javascript
// New features to add to your frontend/backend

// 1. Check eligibility before showing claim buttons
const eligibility = await checkGumDropEligibility(userAddress);

if (eligibility.canClaimCheckIn) {
  showCheckInButton();
}

if (eligibility.canClaimAM && eligibility.isAMHours) {
  showAMBonusButton();
}

// 2. Store claim history in Supabase for analytics (optional)
await supabase.from('gumdrop_claims').insert({
  user_address: address,
  claim_type: 'daily_checkin',
  amount: 15.0,
  streak: 5,
  timestamp: new Date()
});

// 3. Show streak progress in UI
displayStreakBadge(eligibility.currentStreak);
```

---

## Example User Journey

**Day 1 - Morning (9am UTC)**
```
1. ✅ Claim daily check-in: 10 GUM (streak: 1)
2. ✅ Claim AM bonus: 5 GUM
3. ✅ Claim Flunks holder bonus: 6 GUM (owns 3 Flunks)
Total: 21 GUM
```

**Day 1 - Evening (8pm UTC)**
```
4. ✅ Claim PM bonus: 5 GUM
Total for Day 1: 26 GUM
```

**Day 2 - Morning (10am UTC)**
```
1. ✅ Claim daily check-in: 11 GUM (streak: 2)
2. ✅ Claim AM bonus: 5 GUM
Total so far: 16 GUM
```

**Day 3 - MISSED**
```
❌ No claims (streak resets)
```

**Day 4 - Morning (7am UTC)**
```
1. ✅ Claim daily check-in: 10 GUM (streak: 1 - reset)
2. ✅ Claim scheduled drop #5: 10 GUM
Total: 20 GUM
```

---

## Flow Actions Integration (Hackathon Feature!)

While the current GUMDrops contract doesn't yet use Flow Actions interfaces directly, you can enhance it to qualify for the **Forte Hackathon** by adding:

### 1. **Source Interface** for GUM Claims
Make claims work as Flow Actions `Source` providers:

```cadence
// Convert GUMDrops claims into Flow Actions Sources
access(all) struct CheckInSource: Source {
  // Implement Source interface
  // Provides GUM tokens from check-in rewards
}
```

### 2. **Sink Interface** for Scheduled Drops
Allow drops to work as Flow Actions `Sink` receivers:

```cadence
// Accept GUM deposits for scheduled drops
access(all) struct DropSink: Sink {
  // Implement Sink interface
  // Fills scheduled drop pools
}
```

### 3. **Composable Workflows**
Combine with other Flow Actions:

```cadence
// Example: Check-in → Swap → Stake in one transaction
CheckInSource → Swapper (GUM→FLOW) → StakeSink
```

---

## Constants (Adjustable by Admin)

```cadence
BASE_CHECKIN_REWARD: 10.0 GUM
STREAK_BONUS_MULTIPLIER: 1.0 GUM per day
AM_BONUS: 5.0 GUM
PM_BONUS: 5.0 GUM
FLUNKS_HOLDER_BONUS: 2.0 GUM per Flunks
SECONDS_PER_DAY: 86400.0
```

---

## Events

Monitor these events for analytics:

```cadence
CheckInClaimed(address, amount, timestamp, streak)
TimeBonusClaimed(address, amount, timeOfDay)
FlunksHolderBonusClaimed(address, amount, flunksCount)
DropScheduleCreated(dropID, totalAmount, startTime)
DropClaimed(dropID, address, amount)
```

---

## FAQ

### Q: Will this conflict with my existing staking system?
**A:** No! GUMDrops is completely separate. Users can claim both staking rewards AND GUMDrops rewards.

### Q: Do I need to modify my Supabase backend?
**A:** No! It works standalone. But you CAN integrate it for better UX (showing eligibility, tracking claims, etc.)

### Q: Can I adjust the reward amounts?
**A:** Yes, but you'll need to redeploy the contract. Future versions could add admin functions to update these on-chain.

### Q: What about timezone issues?
**A:** Currently uses UTC for AM/PM hours. You can enhance the contract to support user timezones or use local time calculation in your frontend.

### Q: How does this qualify for the Forte hackathon?
**A:** By adding Flow Actions interfaces (Source/Sink/Swapper) to the GUMDrops system, you demonstrate composable DeFi workflows - exactly what Forte/Flow Actions enables!

---

## Next Steps

1. ✅ Deploy `GUMDrops.cdc` contract
2. ✅ Test transactions on testnet
3. ✅ Integrate with your frontend
4. 🚀 Add Flow Actions interfaces for hackathon
5. 🚀 Create time-based NFT metadata updates (AM/PM photos)
6. 🚀 Build composable workflows

---

## Support

For issues or questions, check:
- Flow Actions Documentation: https://developers.flow.com/blockchain-development-tutorials/forte/flow-actions
- Flunks Discord: [Your Discord Link]
- GitHub Issues: https://github.com/Flunks-Community/flunks.flow
