# GUM - Website-Only Currency System

## 🎯 What GUM Really Is

**GUM is NOT a blockchain token.** It's a **website-only points/currency system** that:

✅ Lives entirely in **Supabase** (your existing setup)  
✅ Users earn through daily logins, check-ins, activities  
✅ Users can **transfer GUM to each other** on the website  
✅ Users spend GUM to **buy NFTs on your website**  
✅ Users spend GUM to **play games** on your website  
❌ **NOT withdrawable** to blockchain  
❌ **NOT tradeable** on DEXs  
❌ **NO gas fees** ever  

This is essentially like **Xbox points**, **V-Bucks**, or **Reddit karma** - it only exists on your platform!

---

## 📊 Your Existing Supabase Schema (Perfect!)

You already have the right setup:

```sql
-- User balances (website-only GUM)
CREATE TABLE user_gum_balances (
  id SERIAL PRIMARY KEY,
  wallet_address VARCHAR(64) UNIQUE NOT NULL,
  total_gum BIGINT DEFAULT 0 NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT positive_gum_balance CHECK (total_gum >= 0)
);

-- All GUM transactions (earning, spending, transfers)
CREATE TABLE gum_transactions (
  id SERIAL PRIMARY KEY,
  wallet_address VARCHAR(64) NOT NULL,
  transaction_type VARCHAR(32) NOT NULL, -- 'earned', 'spent', 'bonus', 'transfer_in', 'transfer_out'
  amount INTEGER NOT NULL,
  source VARCHAR(64) NOT NULL,
  description TEXT,
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Daily login/checkin cooldowns
CREATE TABLE user_gum_cooldowns (
  id SERIAL PRIMARY KEY,
  wallet_address VARCHAR(64) NOT NULL,
  source_name VARCHAR(64) NOT NULL,
  last_earned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  daily_earned_amount INTEGER DEFAULT 0,
  daily_reset_date DATE DEFAULT CURRENT_DATE,
  UNIQUE(wallet_address, source_name)
);

-- GUM earning sources
CREATE TABLE gum_sources (
  id SERIAL PRIMARY KEY,
  source_name VARCHAR(64) UNIQUE NOT NULL,
  base_reward INTEGER NOT NULL,
  cooldown_minutes INTEGER DEFAULT 0,
  daily_limit INTEGER,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

---

## ✨ New Features to Add

### 1. **GUM Transfers Between Users**

```sql
-- Add new transaction type for transfers
-- Already supported by your gum_transactions table!

-- Transfer function
CREATE OR REPLACE FUNCTION transfer_gum(
  from_wallet VARCHAR(64),
  to_wallet VARCHAR(64),
  amount INTEGER,
  message TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  sender_balance INTEGER;
  result JSONB;
BEGIN
  -- Check sender balance
  SELECT total_gum INTO sender_balance
  FROM user_gum_balances
  WHERE wallet_address = from_wallet;
  
  IF sender_balance IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Sender not found');
  END IF;
  
  IF sender_balance < amount THEN
    RETURN jsonb_build_object('success', false, 'error', 'Insufficient balance');
  END IF;
  
  -- Ensure recipient exists
  INSERT INTO user_gum_balances (wallet_address, total_gum)
  VALUES (to_wallet, 0)
  ON CONFLICT (wallet_address) DO NOTHING;
  
  -- Deduct from sender
  UPDATE user_gum_balances
  SET total_gum = total_gum - amount,
      updated_at = CURRENT_TIMESTAMP
  WHERE wallet_address = from_wallet;
  
  -- Add to recipient
  UPDATE user_gum_balances
  SET total_gum = total_gum + amount,
      updated_at = CURRENT_TIMESTAMP
  WHERE wallet_address = to_wallet;
  
  -- Record sender transaction
  INSERT INTO gum_transactions (wallet_address, transaction_type, amount, source, description, metadata)
  VALUES (
    from_wallet,
    'transfer_out',
    amount,
    'user_transfer',
    COALESCE(message, 'Sent GUM to ' || to_wallet),
    jsonb_build_object('to_wallet', to_wallet, 'message', message)
  );
  
  -- Record recipient transaction
  INSERT INTO gum_transactions (wallet_address, transaction_type, amount, source, description, metadata)
  VALUES (
    to_wallet,
    'transfer_in',
    amount,
    'user_transfer',
    COALESCE(message, 'Received GUM from ' || from_wallet),
    jsonb_build_object('from_wallet', from_wallet, 'message', message)
  );
  
  RETURN jsonb_build_object(
    'success', true,
    'transferred', amount,
    'new_balance', sender_balance - amount
  );
END;
$$ LANGUAGE plpgsql;
```

### 2. **Spend GUM on NFT Purchases**

```sql
-- Function to spend GUM on NFT purchases
CREATE OR REPLACE FUNCTION spend_gum_on_nft(
  buyer_wallet VARCHAR(64),
  nft_id VARCHAR(64),
  price INTEGER,
  nft_name TEXT
)
RETURNS JSONB AS $$
DECLARE
  buyer_balance INTEGER;
BEGIN
  -- Check balance
  SELECT total_gum INTO buyer_balance
  FROM user_gum_balances
  WHERE wallet_address = buyer_wallet;
  
  IF buyer_balance IS NULL OR buyer_balance < price THEN
    RETURN jsonb_build_object('success', false, 'error', 'Insufficient GUM');
  END IF;
  
  -- Deduct GUM
  UPDATE user_gum_balances
  SET total_gum = total_gum - price,
      updated_at = CURRENT_TIMESTAMP
  WHERE wallet_address = buyer_wallet;
  
  -- Record transaction
  INSERT INTO gum_transactions (wallet_address, transaction_type, amount, source, description, metadata)
  VALUES (
    buyer_wallet,
    'spent',
    price,
    'nft_purchase',
    'Purchased NFT: ' || nft_name,
    jsonb_build_object('nft_id', nft_id, 'nft_name', nft_name, 'price', price)
  );
  
  RETURN jsonb_build_object(
    'success', true,
    'spent', price,
    'new_balance', buyer_balance - price,
    'nft_id', nft_id
  );
END;
$$ LANGUAGE plpgsql;
```

### 3. **Spend GUM on Games**

```sql
-- Function to spend GUM on game entry fees
CREATE OR REPLACE FUNCTION spend_gum_on_game(
  player_wallet VARCHAR(64),
  game_id VARCHAR(64),
  entry_fee INTEGER,
  game_name TEXT
)
RETURNS JSONB AS $$
DECLARE
  player_balance INTEGER;
BEGIN
  -- Check balance
  SELECT total_gum INTO player_balance
  FROM user_gum_balances
  WHERE wallet_address = player_wallet;
  
  IF player_balance IS NULL OR player_balance < entry_fee THEN
    RETURN jsonb_build_object('success', false, 'error', 'Insufficient GUM');
  END IF;
  
  -- Deduct GUM
  UPDATE user_gum_balances
  SET total_gum = total_gum - entry_fee,
      updated_at = CURRENT_TIMESTAMP
  WHERE wallet_address = player_wallet;
  
  -- Record transaction
  INSERT INTO gum_transactions (wallet_address, transaction_type, amount, source, description, metadata)
  VALUES (
    player_wallet,
    'spent',
    entry_fee,
    'game_entry',
    'Played game: ' || game_name,
    jsonb_build_object('game_id', game_id, 'game_name', game_name, 'entry_fee', entry_fee)
  );
  
  RETURN jsonb_build_object(
    'success', true,
    'spent', entry_fee,
    'new_balance', player_balance - entry_fee,
    'game_id', game_id
  );
END;
$$ LANGUAGE plpgsql;
```

---

## 🔌 API Routes

### Transfer GUM to Another User

```typescript
// app/api/gum/transfer/route.ts
import { createClient } from '@supabase/supabase-js';

export async function POST(req: Request) {
  const { fromWallet, toWallet, amount, message } = await req.json();
  
  // Validate
  if (!fromWallet || !toWallet || amount <= 0) {
    return Response.json({ error: 'Invalid transfer details' }, { status: 400 });
  }
  
  if (fromWallet === toWallet) {
    return Response.json({ error: 'Cannot transfer to yourself' }, { status: 400 });
  }
  
  const supabase = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
  );
  
  // Call transfer function
  const { data, error } = await supabase.rpc('transfer_gum', {
    from_wallet: fromWallet,
    to_wallet: toWallet,
    amount: amount,
    message: message
  });
  
  if (error || !data.success) {
    return Response.json({ 
      error: data?.error || 'Transfer failed' 
    }, { status: 400 });
  }
  
  return Response.json({
    success: true,
    transferred: amount,
    newBalance: data.new_balance,
    message: `Sent ${amount} GUM to ${toWallet}`
  });
}
```

### Purchase NFT with GUM

```typescript
// app/api/nft/purchase-with-gum/route.ts
export async function POST(req: Request) {
  const { buyerWallet, nftId, price, nftName } = await req.json();
  
  const supabase = createClient(...);
  
  // Spend GUM
  const { data, error } = await supabase.rpc('spend_gum_on_nft', {
    buyer_wallet: buyerWallet,
    nft_id: nftId,
    price: price,
    nft_name: nftName
  });
  
  if (error || !data.success) {
    return Response.json({ error: data?.error || 'Purchase failed' }, { status: 400 });
  }
  
  // Now mint/transfer the NFT on-chain
  try {
    const txId = await mintNFTToUser(buyerWallet, nftId);
    
    return Response.json({
      success: true,
      nftId: nftId,
      spent: price,
      newBalance: data.new_balance,
      txId: txId,
      message: `Successfully purchased ${nftName}!`
    });
  } catch (mintError) {
    // Refund GUM if NFT minting fails
    await supabase.rpc('award_gum', {
      wallet_address: buyerWallet,
      source: 'refund',
      metadata: { reason: 'nft_mint_failed', nft_id: nftId }
    });
    
    return Response.json({ error: 'NFT minting failed - GUM refunded' }, { status: 500 });
  }
}
```

### Play Game with GUM

```typescript
// app/api/game/enter/route.ts
export async function POST(req: Request) {
  const { playerWallet, gameId, entryFee, gameName } = await req.json();
  
  const supabase = createClient(...);
  
  // Deduct entry fee
  const { data, error } = await supabase.rpc('spend_gum_on_game', {
    player_wallet: playerWallet,
    game_id: gameId,
    entry_fee: entryFee,
    game_name: gameName
  });
  
  if (error || !data.success) {
    return Response.json({ error: data?.error || 'Insufficient GUM' }, { status: 400 });
  }
  
  // Create game session
  const { data: session } = await supabase.from('game_sessions').insert({
    player_wallet: playerWallet,
    game_id: gameId,
    entry_fee: entryFee,
    status: 'active',
    started_at: new Date().toISOString()
  }).select().single();
  
  return Response.json({
    success: true,
    sessionId: session.id,
    spent: entryFee,
    newBalance: data.new_balance,
    message: `Game started! Entry fee: ${entryFee} GUM`
  });
}
```

---

## 🎮 Frontend Components

### Transfer GUM Component

```tsx
'use client';

import { useState } from 'react';

export function TransferGUM({ fromWallet }: { fromWallet: string }) {
  const [toWallet, setToWallet] = useState('');
  const [amount, setAmount] = useState(0);
  const [message, setMessage] = useState('');
  const [loading, setLoading] = useState(false);
  
  const handleTransfer = async () => {
    setLoading(true);
    
    try {
      const res = await fetch('/api/gum/transfer', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          fromWallet: fromWallet,
          toWallet: toWallet,
          amount: amount,
          message: message
        })
      });
      
      const data = await res.json();
      
      if (data.success) {
        alert(`✅ Sent ${amount} GUM to ${toWallet}!`);
        setToWallet('');
        setAmount(0);
        setMessage('');
        // Refresh balance
        window.dispatchEvent(new CustomEvent('gumBalanceChanged'));
      } else {
        alert(`❌ ${data.error}`);
      }
    } catch (error) {
      alert('Transfer failed');
    } finally {
      setLoading(false);
    }
  };
  
  return (
    <div className="transfer-gum-card">
      <h3>Send GUM</h3>
      
      <input
        type="text"
        placeholder="Recipient wallet address"
        value={toWallet}
        onChange={(e) => setToWallet(e.target.value)}
      />
      
      <input
        type="number"
        placeholder="Amount"
        value={amount}
        onChange={(e) => setAmount(Number(e.target.value))}
        min={1}
      />
      
      <input
        type="text"
        placeholder="Message (optional)"
        value={message}
        onChange={(e) => setMessage(e.target.value)}
      />
      
      <button
        onClick={handleTransfer}
        disabled={loading || !toWallet || amount <= 0}
      >
        {loading ? 'Sending...' : `Send ${amount} GUM`}
      </button>
    </div>
  );
}
```

### Buy NFT with GUM

```tsx
export function BuyWithGUM({ 
  nft,
  userWallet 
}: { 
  nft: { id: string; name: string; gumPrice: number },
  userWallet: string
}) {
  const handlePurchase = async () => {
    const res = await fetch('/api/nft/purchase-with-gum', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        buyerWallet: userWallet,
        nftId: nft.id,
        price: nft.gumPrice,
        nftName: nft.name
      })
    });
    
    const data = await res.json();
    
    if (data.success) {
      alert(`🎉 You bought ${nft.name} for ${nft.gumPrice} GUM!`);
      alert(`Transaction: ${data.txId}`);
      // Refresh NFT collection
    } else {
      alert(`❌ ${data.error}`);
    }
  };
  
  return (
    <div className="nft-purchase-card">
      <h4>{nft.name}</h4>
      <p className="price">💎 {nft.gumPrice} GUM</p>
      <button onClick={handlePurchase}>
        Buy Now
      </button>
    </div>
  );
}
```

---

## 🚫 What to REMOVE from Blockchain Contract

Since GUM is **website-only**, you should:

### ❌ DELETE These Files:
- `GUMDrops.cdc` (old version)
- `GUMDrops_Clean.cdc` (the one I just created - NOT NEEDED!)
- Any GUM withdrawal transactions
- Any GUM minting contracts

### ✅ KEEP for NFTs:
- `Flunks.cdc` - Your NFT collection
- `Backpack.cdc` - Another NFT collection
- Any NFT-related contracts

### 🆕 What You DO Need on Blockchain:

**Only the NFT minting** when users buy with GUM:

```cadence
// Simple NFT minting transaction
// Called by your backend AFTER user pays with GUM

import Flunks from "./contracts/Flunks.cdc"
import NonFungibleToken from "./contracts/NonFungibleToken.cdc"

transaction(recipientAddress: Address, nftName: String, nftImage: String, metadata: {String: String}) {
    let minter: &Flunks.NFTMinter
    let recipientCollection: &{NonFungibleToken.CollectionPublic}
    
    prepare(signer: auth(Storage, BorrowValue) &Account) {
        // Admin mints NFT
        self.minter = signer.storage.borrow<&Flunks.NFTMinter>(
            from: Flunks.MinterStoragePath
        ) ?? panic("Could not borrow minter")
        
        // Get recipient's collection
        let account = getAccount(recipientAddress)
        self.recipientCollection = account.capabilities.get<&{NonFungibleToken.CollectionPublic}>(
            Flunks.CollectionPublicPath
        ).borrow() ?? panic("Could not borrow collection")
    }
    
    execute {
        // Mint NFT to user
        self.minter.mintNFT(
            recipient: self.recipientCollection,
            name: nftName,
            description: "Purchased with GUM",
            thumbnail: nftImage,
            metadata: metadata
        )
    }
}
```

---

## 📊 Summary: GUM System Architecture

```
┌─────────────────────────────────────────────────────┐
│              WEBSITE (Supabase Only)                 │
├─────────────────────────────────────────────────────┤
│  ✅ Earn GUM (daily login, checkin, activities)      │
│  ✅ Transfer GUM between users                       │
│  ✅ Spend GUM on NFTs                                │
│  ✅ Spend GUM on games                               │
│  ✅ View transaction history                         │
│  ✅ Leaderboards                                     │
│                                                      │
│  → All GUM operations in Supabase                   │
│  → NO blockchain GUM token                          │
│  → NO withdrawals needed                            │
└─────────────────────────────────────────────────────┘
                          ↓
                   (When user buys NFT)
                          ↓
┌─────────────────────────────────────────────────────┐
│            BLOCKCHAIN (NFTs Only)                    │
├─────────────────────────────────────────────────────┤
│  1. User pays GUM in Supabase                        │
│  2. Backend mints NFT on Flow                        │
│  3. NFT sent to user's wallet                        │
│                                                      │
│  → NFTs are on-chain                                │
│  → GUM stays on website                             │
└─────────────────────────────────────────────────────┘
```

**This is MUCH simpler and better for your use case!** 🎉

No blockchain GUM token = No gas fees, no complexity, instant transfers, full control!
