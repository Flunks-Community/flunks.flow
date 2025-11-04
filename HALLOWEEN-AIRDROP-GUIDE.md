# 🎃 Halloween GUM Airdrop Guide

## Overview

This guide shows you how to "hardwire" GUM into user accounts for a Halloween airdrop using the SemesterZero contract.

## Two Airdrop Methods

### Method 1: Special Drop (Recommended) ⭐
**Users claim the airdrop themselves on your website**

**Pros:**
- Users feel engaged (they click to claim)
- Time-limited scarcity creates urgency
- Tracks who claimed automatically
- Can require Flunks ownership
- No need to know addresses beforehand

**Cons:**
- Users must take action
- Some eligible users might miss it

### Method 2: Batch Airdrop
**You push GUM directly to user accounts**

**Pros:**
- Guaranteed delivery
- No user action required
- Perfect for rewarding specific users

**Cons:**
- Must know addresses beforehand
- Less engaging for users
- Requires admin transaction for each batch

---

## Setup Instructions

### 1. Deploy SemesterZero Contract (First Time Only)

```bash
# Testnet
flow project deploy --network testnet

# Mainnet
flow project deploy --network mainnet
```

### 2. Verify Deployment

```bash
# Check active drops
flow scripts execute ./cadence/scripts/check-halloween-drop.cdc --network testnet
```

---

## Method 1: Create a Special Drop (Recommended)

### Step 1: Create the Halloween Drop

```bash
flow transactions send ./cadence/transactions/halloween-create-drop.cdc \
  --arg String:"🎃 Halloween Treat 2025" \
  --arg String:"Spooky GUM treats for all Flunks holders! 👻" \
  --arg UFix64:100.0 \
  --arg UFix64:1729296000.0 \
  --arg UFix64:1730419199.0 \
  --arg Bool:true \
  --arg Int:1 \
  --arg UInt64:1000 \
  --network testnet \
  --signer admin-account
```

**Parameters Explained:**
- `name`: Display name for the drop
- `description`: What users see on website
- `amount`: **100.0** GUM per claim
- `startTime`: Oct 18, 2025 00:00:00 UTC (1729296000)
- `endTime`: Oct 31, 2025 23:59:59 UTC (1730419199)
- `requiredFlunks`: **true** = must own Flunks to claim
- `minFlunksCount`: **1** = need at least 1 Flunks
- `maxClaims`: **1000** = max 1000 people can claim

### Step 2: Display on Website

**Query Active Drops:**
```javascript
// Get all active drops
const drops = await fcl.query({
  cadence: `
    import SemesterZero from 0x...
    
    access(all) fun main(): [SemesterZero.SpecialDropInfo] {
      return SemesterZero.getActiveDrops()
    }
  `
});

// Display on website
drops.forEach(drop => {
  console.log(`Drop: ${drop.name}`);
  console.log(`Amount: ${drop.amount} GUM`);
  console.log(`Claims: ${drop.totalClaims}/${drop.maxClaims}`);
});
```

### Step 3: Users Claim on Website

**User Click Handler:**
```javascript
// User clicks "Claim Halloween GUM" button
async function claimHalloweenDrop(dropID) {
  const txId = await fcl.mutate({
    cadence: `
      import SemesterZero from 0x...
      
      transaction(dropID: UInt64) {
        let gumAccountRef: &SemesterZero.GumAccount
        
        prepare(user: auth(BorrowValue) &Account) {
          self.gumAccountRef = user.storage.borrow<&SemesterZero.GumAccount>(
            from: SemesterZero.GumAccountStoragePath
          ) ?? panic("Please set up your GUM account first")
        }
        
        execute {
          SemesterZero.claimSpecialDrop(
            dropID: dropID,
            gumAccount: self.gumAccountRef
          )
        }
      }
    `,
    args: (arg, t) => [arg(dropID, t.UInt64)]
  });
  
  // Show success message
  alert("🎃 Halloween GUM claimed! Check your balance!");
}
```

### Step 4: Check User Eligibility (Before Claim)

```bash
# Check if specific user can claim
flow scripts execute ./cadence/scripts/check-user-drop-eligibility.cdc \
  --arg Address:0x1234567890123456 \
  --arg UInt64:1 \
  --network testnet
```

---

## Method 2: Batch Direct Airdrop

### Option A: Using the Script

1. Edit `halloween-airdrop.sh` and add your recipient addresses:

```bash
RECIPIENTS=(
    "0x1234567890123456"
    "0x2345678901234567"
    "0x3456789012345678"
)

AMOUNTS=(
    "100.0"  # First user gets 100 GUM
    "150.0"  # Second user gets 150 GUM
    "200.0"  # Third user gets 200 GUM
)
```

2. Run the batch airdrop:

```bash
chmod +x halloween-airdrop.sh
./halloween-airdrop.sh batch
```

### Option B: Manual Transaction

```bash
flow transactions send ./cadence/transactions/halloween-batch-airdrop.cdc \
  --arg Address:0x1234567890123456 --arg UFix64:100.0 \
  --arg Address:0x2345678901234567 --arg UFix64:150.0 \
  --arg Address:0x3456789012345678 --arg UFix64:200.0 \
  --network testnet \
  --signer admin-account
```

**Note:** This adds GUM on top of their existing balance using the `syncUserBalance()` admin function.

---

## Website Integration Examples

### React Component Example

```jsx
import { useState, useEffect } from 'react';
import * as fcl from '@onflow/fcl';

function HalloweenAirdrop() {
  const [drops, setDrops] = useState([]);
  const [loading, setLoading] = useState(false);
  
  useEffect(() => {
    loadDrops();
  }, []);
  
  async function loadDrops() {
    const activeDrops = await fcl.query({
      cadence: `
        import SemesterZero from 0x...
        access(all) fun main(): [SemesterZero.SpecialDropInfo] {
          return SemesterZero.getActiveDrops()
        }
      `
    });
    setDrops(activeDrops);
  }
  
  async function claimDrop(dropID) {
    setLoading(true);
    try {
      const txId = await fcl.mutate({
        cadence: CLAIM_DROP_TRANSACTION,
        args: (arg, t) => [arg(dropID, t.UInt64)]
      });
      
      await fcl.tx(txId).onceSealed();
      alert('🎃 Halloween GUM claimed!');
      loadDrops(); // Refresh
      
    } catch (error) {
      alert('Error claiming: ' + error.message);
    } finally {
      setLoading(false);
    }
  }
  
  return (
    <div className="halloween-airdrop">
      <h2>🎃 Halloween Special Drops</h2>
      {drops.map(drop => (
        <div key={drop.dropID} className="drop-card">
          <h3>{drop.name}</h3>
          <p>{drop.description}</p>
          <p>Amount: {drop.amount} GUM</p>
          <p>Claimed: {drop.totalClaims}/{drop.maxClaims}</p>
          <button 
            onClick={() => claimDrop(drop.dropID)}
            disabled={loading || !drop.isActive}
          >
            {loading ? 'Claiming...' : 'Claim Now 🎃'}
          </button>
        </div>
      ))}
    </div>
  );
}
```

---

## Important Dates & Timestamps

**Halloween 2025:**
- Start: October 18, 2025 00:00:00 UTC = `1729296000`
- End: October 31, 2025 23:59:59 UTC = `1730419199`

**Generate Timestamps:**
```bash
# macOS
date -j -f "%Y-%m-%d %H:%M:%S" "2025-10-18 00:00:00" +%s

# Linux
date -d "2025-10-18 00:00:00" +%s
```

---

## Monitoring & Analytics

### Check Drop Status
```bash
./halloween-airdrop.sh check
```

### Check Specific User
```bash
./halloween-airdrop.sh check-user 0x1234... 1
```

### Export Claims (via Flow Event)
```bash
# Query SpecialDropClaimed events
flow events get A.CONTRACT.SemesterZero.SpecialDropClaimed \
  --start BLOCK_HEIGHT \
  --end BLOCK_HEIGHT \
  --network testnet
```

---

## Recommended: Halloween Drop Configuration

```bash
# Create Halloween drop with these settings:
- Name: "🎃 Halloween Treat 2025"
- Amount: 100 GUM
- Duration: Oct 18-31, 2025
- Required: 1+ Flunks
- Max Claims: 1000
- Total GUM allocated: 100,000 GUM
```

This creates FOMO and engagement while rewarding your community! 👻

---

## Troubleshooting

### "User does not have GUM account"
Users need to set up their account first:
```cadence
// Setup transaction (run once per user)
transaction {
  prepare(user: auth(Storage, Capabilities) &Account) {
    if user.storage.borrow<&SemesterZero.GumAccount>(
      from: SemesterZero.GumAccountStoragePath
    ) == nil {
      let gumAccount <- SemesterZero.createGumAccount(initialBalance: 0.0)
      user.storage.save(<-gumAccount, to: SemesterZero.GumAccountStoragePath)
      
      let cap = user.capabilities.storage.issue<&SemesterZero.GumAccount>(
        SemesterZero.GumAccountStoragePath
      )
      user.capabilities.publish(cap, at: SemesterZero.GumAccountPublicPath)
    }
  }
}
```

### "Drop not found"
- Check dropID is correct
- Verify drop is still active (within time window)
- Run `./halloween-airdrop.sh check` to see all drops

### "Already claimed"
- Each address can only claim once per drop
- This is tracked on-chain automatically

---

## Next Steps

1. **Deploy SemesterZero** if not already deployed
2. **Create Halloween Drop** using the transaction
3. **Add UI to website** for users to claim
4. **Monitor claims** and track engagement
5. **Share on social media** to drive awareness! 🎃👻

Questions? Check the contract at `cadence/contracts/SemesterZero.cdc`
