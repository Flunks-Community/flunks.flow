# GUMDrops - Supabase Integration Guide

## 🎯 Overview

**GUMDrops** is designed to work with your Supabase-based GUM earning system. 

### How It Works

```
┌─────────────────────────────────────────────────────────┐
│                    WEBSITE (Supabase)                    │
├─────────────────────────────────────────────────────────┤
│  ✅ Daily locker claims                                  │
│  ✅ Profile updates                                      │
│  ✅ Social engagement                                    │
│  ✅ Referrals                                            │
│  ✅ All activity tracking                                │
│                                                          │
│  → GUM balance stored in database                       │
│  → Users can withdraw to blockchain when ready          │
└─────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────┐
│              BLOCKCHAIN (GUMDrops.cdc)                   │
├─────────────────────────────────────────────────────────┤
│  ✅ Withdraw GUM from website to wallet                  │
│  ✅ On-chain Flunks holder bonus verification           │
│  ✅ Special event drops (admin-created)                 │
│  ✅ NFT-gated airdrops                                  │
└─────────────────────────────────────────────────────────┘
```

---

## 📦 What's Removed (Old Staking System)

❌ **Removed from GUMDrops:**
- On-chain daily check-in tracking
- On-chain streak bonuses
- On-chain AM/PM bonuses  
- ClaimTracker resource
- UserClaimData struct

✅ **All these are now in Supabase** (your website database)

---

## 🆕 What GUMDrops Does Now

### 1. **Website → Wallet Withdrawals**
```cadence
// Admin function (called by backend)
Admin.withdrawGUMToWallet(
    recipient: userAddress,
    amount: databaseBalance,
    withdrawalID: "uuid-from-supabase"
)
```

**Flow:**
1. User earns GUM on website (tracked in Supabase)
2. User clicks "Withdraw to Wallet"
3. Backend calls this function (admin signature)
4. GUM minted and sent to user's Flow wallet
5. Database balance reduced

### 2. **On-Chain Flunks Holder Bonus**
```cadence
// User transaction - verifies NFT ownership on-chain
GUMDrops.claimFlunksHolderBonus(claimer: signer)
```

**Why on-chain?**
- Must verify actual NFT ownership
- Can't be faked in database
- 2 GUM per Flunks owned

### 3. **Special Event Drops**
```cadence
// Admin creates special drops for events
Admin.createSpecialDrop(
    totalAmount: 10000.0,
    amountPerClaim: 100.0,
    startTime: eventTimestamp,
    endTime: eventTimestamp + 86400,
    requiresFlunks: true,
    description: "Halloween 2025 Drop"
)
```

**Use cases:**
- Holiday events
- Milestone celebrations
- Community rewards
- Limited-time bonuses

---

## 💾 Supabase Schema

### Tables You Need

```sql
-- User GUM balances (website earnings)
CREATE TABLE user_gum_balance (
  user_address TEXT PRIMARY KEY,
  balance DECIMAL NOT NULL DEFAULT 0,
  total_earned DECIMAL NOT NULL DEFAULT 0,
  total_withdrawn DECIMAL NOT NULL DEFAULT 0,
  last_updated TIMESTAMP DEFAULT NOW()
);

-- Track all GUM earning activities
CREATE TABLE gum_earnings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_address TEXT NOT NULL,
  amount DECIMAL NOT NULL,
  activity_type TEXT NOT NULL, -- 'daily_locker', 'profile_update', 'referral', 'social_share', etc.
  metadata JSONB, -- Store additional activity info
  earned_at TIMESTAMP DEFAULT NOW(),
  FOREIGN KEY (user_address) REFERENCES user_gum_balance(user_address)
);

-- Track withdrawals to blockchain
CREATE TABLE gum_withdrawals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_address TEXT NOT NULL,
  amount DECIMAL NOT NULL,
  tx_id TEXT, -- Flow transaction ID
  status TEXT DEFAULT 'pending', -- 'pending', 'completed', 'failed'
  error_message TEXT,
  requested_at TIMESTAMP DEFAULT NOW(),
  completed_at TIMESTAMP,
  FOREIGN KEY (user_address) REFERENCES user_gum_balance(user_address)
);

-- Daily locker claims (your existing mechanism)
CREATE TABLE daily_locker_claims (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_address TEXT NOT NULL,
  claim_date DATE NOT NULL,
  gum_earned DECIMAL NOT NULL,
  streak_days INT DEFAULT 1,
  claimed_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_address, claim_date)
);
```

---

## 🔌 API Endpoints

### 1. Daily Locker Claim
```typescript
// app/api/claim-daily-locker/route.ts
import { createClient } from '@supabase/supabase-js';

export async function POST(req: Request) {
  const { userAddress } = await req.json();
  
  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
  );
  
  // Check if already claimed today
  const today = new Date().toISOString().split('T')[0];
  const { data: existingClaim } = await supabase
    .from('daily_locker_claims')
    .select('*')
    .eq('user_address', userAddress)
    .eq('claim_date', today)
    .single();
  
  if (existingClaim) {
    return Response.json({ error: 'Already claimed today' }, { status: 400 });
  }
  
  // Calculate streak
  const yesterday = new Date(Date.now() - 86400000).toISOString().split('T')[0];
  const { data: yesterdayClaim } = await supabase
    .from('daily_locker_claims')
    .select('streak_days')
    .eq('user_address', userAddress)
    .eq('claim_date', yesterday)
    .single();
  
  const streakDays = yesterdayClaim ? yesterdayClaim.streak_days + 1 : 1;
  
  // Calculate reward (base + streak bonus)
  const baseReward = 10.0;
  const streakBonus = streakDays * 1.0;
  const totalReward = baseReward + streakBonus;
  
  // Record claim
  await supabase.from('daily_locker_claims').insert({
    user_address: userAddress,
    claim_date: today,
    gum_earned: totalReward,
    streak_days: streakDays
  });
  
  // Update balance
  await supabase.rpc('increment_gum_balance', {
    p_user_address: userAddress,
    p_amount: totalReward
  });
  
  // Log earning activity
  await supabase.from('gum_earnings').insert({
    user_address: userAddress,
    amount: totalReward,
    activity_type: 'daily_locker',
    metadata: { streak_days: streakDays }
  });
  
  return Response.json({
    success: true,
    reward: totalReward,
    streak: streakDays
  });
}
```

### 2. Withdraw GUM to Wallet
```typescript
// app/api/withdraw-gum/route.ts
import * as fcl from '@onflow/fcl';

export async function POST(req: Request) {
  const { userAddress, amount } = await req.json();
  
  const supabase = createClient(...);
  
  // 1. Check database balance
  const { data: user } = await supabase
    .from('user_gum_balance')
    .select('balance')
    .eq('user_address', userAddress)
    .single();
  
  if (!user || user.balance < amount) {
    return Response.json({ error: 'Insufficient balance' }, { status: 400 });
  }
  
  // 2. Create pending withdrawal record
  const { data: withdrawal } = await supabase
    .from('gum_withdrawals')
    .insert({
      user_address: userAddress,
      amount: amount,
      status: 'pending'
    })
    .select()
    .single();
  
  try {
    // 3. Execute blockchain transaction (admin signs)
    const txId = await fcl.mutate({
      cadence: `
        import GUMDrops from 0xYOUR_CONTRACT_ADDRESS
        import GUM from 0xYOUR_GUM_ADDRESS
        
        transaction(recipient: Address, amount: UFix64, withdrawalID: String) {
          let admin: &GUMDrops.Admin
          
          prepare(signer: auth(Storage, BorrowValue) &Account) {
            self.admin = signer.storage.borrow<&GUMDrops.Admin>(
              from: GUMDrops.AdminStoragePath
            ) ?? panic("Could not borrow admin")
          }
          
          execute {
            // Ensure user has GUM vault setup
            self.admin.withdrawGUMToWallet(
              recipient: recipient,
              amount: amount,
              withdrawalID: withdrawalID
            )
          }
        }
      `,
      args: (arg, t) => [
        arg(userAddress, t.Address),
        arg(amount.toFixed(8), t.UFix64),
        arg(withdrawal.id, t.String)
      ],
      authorizations: [adminAuthorizationFunction],
      limit: 1000
    });
    
    // 4. Update database on success
    await supabase.from('user_gum_balance').update({
      balance: user.balance - amount,
      total_withdrawn: (user.total_withdrawn || 0) + amount
    }).eq('user_address', userAddress);
    
    await supabase.from('gum_withdrawals').update({
      tx_id: txId,
      status: 'completed',
      completed_at: new Date().toISOString()
    }).eq('id', withdrawal.id);
    
    return Response.json({
      success: true,
      txId: txId,
      explorerUrl: `https://flowscan.io/transaction/${txId}`
    });
    
  } catch (error) {
    // Mark as failed
    await supabase.from('gum_withdrawals').update({
      status: 'failed',
      error_message: error.message
    }).eq('id', withdrawal.id);
    
    return Response.json({ error: error.message }, { status: 500 });
  }
}
```

### 3. Earn GUM from Activity
```typescript
// app/api/earn-gum/route.ts
export async function POST(req: Request) {
  const { userAddress, activityType, metadata } = await req.json();
  
  const supabase = createClient(...);
  
  // Define reward amounts
  const rewards = {
    'profile_update': 5.0,
    'social_share': 10.0,
    'referral_signup': 25.0,
    'first_nft_mint': 50.0,
    'community_event': 20.0
  };
  
  const amount = rewards[activityType] || 0;
  
  if (amount === 0) {
    return Response.json({ error: 'Invalid activity type' }, { status: 400 });
  }
  
  // Update balance
  await supabase.rpc('increment_gum_balance', {
    p_user_address: userAddress,
    p_amount: amount
  });
  
  // Log earning
  await supabase.from('gum_earnings').insert({
    user_address: userAddress,
    amount: amount,
    activity_type: activityType,
    metadata: metadata
  });
  
  return Response.json({ success: true, earned: amount });
}
```

---

## 🔐 Supabase Functions

```sql
-- Function to increment GUM balance
CREATE OR REPLACE FUNCTION increment_gum_balance(
  p_user_address TEXT,
  p_amount DECIMAL
)
RETURNS VOID AS $$
BEGIN
  INSERT INTO user_gum_balance (user_address, balance, total_earned)
  VALUES (p_user_address, p_amount, p_amount)
  ON CONFLICT (user_address)
  DO UPDATE SET
    balance = user_gum_balance.balance + p_amount,
    total_earned = user_gum_balance.total_earned + p_amount,
    last_updated = NOW();
END;
$$ LANGUAGE plpgsql;
```

---

## 🎮 Frontend Components

```tsx
// components/GUMBalance.tsx
'use client';

import { useState, useEffect } from 'react';
import { useCurrentUser } from '@/hooks/useCurrentUser';

export function GUMBalance() {
  const user = useCurrentUser();
  const [balance, setBalance] = useState({ database: 0, wallet: 0 });
  const [loading, setLoading] = useState(false);
  
  // Fetch database balance
  useEffect(() => {
    if (!user?.addr) return;
    
    fetch(`/api/gum-balance?address=${user.addr}`)
      .then(res => res.json())
      .then(data => setBalance(prev => ({ ...prev, database: data.balance })));
  }, [user]);
  
  const handleWithdraw = async () => {
    if (!user?.addr || balance.database === 0) return;
    
    setLoading(true);
    try {
      const res = await fetch('/api/withdraw-gum', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          userAddress: user.addr,
          amount: balance.database
        })
      });
      
      const data = await res.json();
      
      if (data.success) {
        alert(`Withdrawal successful! TX: ${data.txId}`);
        // Refresh balance
      }
    } catch (error) {
      console.error('Withdrawal failed:', error);
    } finally {
      setLoading(false);
    }
  };
  
  return (
    <div className="gum-balance-card">
      <h3>Your GUM</h3>
      
      <div className="balance-info">
        <div>
          <label>Website Balance:</label>
          <span>{balance.database.toFixed(2)} GUM</span>
        </div>
        
        <div>
          <label>Wallet Balance:</label>
          <span>{balance.wallet.toFixed(2)} GUM</span>
        </div>
      </div>
      
      <button
        onClick={handleWithdraw}
        disabled={loading || balance.database === 0}
        className="withdraw-btn"
      >
        {loading ? 'Withdrawing...' : 'Withdraw to Wallet'}
      </button>
    </div>
  );
}
```

---

## 📋 Summary

### Your System Now Works Like This:

1. **Earning GUM** (Supabase)
   - Daily locker claims
   - Website activities
   - All tracked in database
   - Instant, no gas fees

2. **Withdrawing GUM** (Blockchain)
   - User requests withdrawal
   - Backend mints & transfers
   - One-time gas cost (you pay)
   - User gets real Flow tokens

3. **Special Bonuses** (Blockchain)
   - Flunks holder bonus (on-chain verification)
   - Event drops (admin creates)
   - NFT-gated airdrops

### No More Old Staking System! ✅

All the old on-chain staking logic is gone. GUM is now:
- Earned on website (Supabase)
- Withdrawn to wallet when needed
- Used for trading/utility on blockchain

This is much more user-friendly and gas-efficient! 🎉
