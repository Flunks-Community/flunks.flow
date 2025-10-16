# GUM Token Refactor Plan - Supabase Integration

## 🎯 Current Situation

### What You Have (Old System)
```
Staking.cdc → NFT staking on-chain
  ↓
GUM rewards calculated on-chain
  ↓
Users claim GUM via transactions
  ↓
GUM lives in Flow wallets
```

### What You Want (New System)
```
Website interaction (Supabase tracked)
  ↓
GUM earned & tracked in database
  ↓
Users can withdraw GUM to Flow wallet when needed
  ↓
GUM becomes real Flow token for trading/utility
```

---

## 📋 Refactor Checklist

### ✅ Phase 1: Keep GUM.cdc Token (Clean Version)

**What to KEEP:**
- ✅ `GUM.cdc` contract (the token itself)
- ✅ `Minter` resource (for website withdrawals)
- ✅ `Burner` resource (for burning when spent)
- ✅ `Vault` resource (user wallet)

**What to REMOVE:**
- ❌ `Staking.cdc` contract (entire file - deprecated)
- ❌ `GUMStakingTracker.cdc` (replaced by Supabase)
- ❌ All staking-related transactions
- ❌ All staking-related scripts

---

## 🔄 New Architecture

### Database Schema (Supabase)
```sql
-- User GUM balances tracked in database
CREATE TABLE user_gum_balance (
  user_address TEXT PRIMARY KEY,
  balance DECIMAL NOT NULL DEFAULT 0,
  total_earned DECIMAL NOT NULL DEFAULT 0,
  last_updated TIMESTAMP DEFAULT NOW()
);

-- GUM earning activities
CREATE TABLE gum_earnings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_address TEXT NOT NULL,
  amount DECIMAL NOT NULL,
  activity_type TEXT NOT NULL, -- 'daily_check_in', 'profile_update', 'referral', etc.
  earned_at TIMESTAMP DEFAULT NOW(),
  withdrawn BOOLEAN DEFAULT FALSE
);

-- GUM withdrawals to blockchain
CREATE TABLE gum_withdrawals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_address TEXT NOT NULL,
  amount DECIMAL NOT NULL,
  tx_id TEXT, -- Flow transaction ID
  status TEXT DEFAULT 'pending', -- 'pending', 'completed', 'failed'
  requested_at TIMESTAMP DEFAULT NOW(),
  completed_at TIMESTAMP
);
```

### Flow Smart Contract (Simplified GUM.cdc)
```cadence
// GUM.cdc - Keep this, remove staking references
access(all) contract GUM: FungibleToken {
    access(all) var totalSupply: UFix64
    
    // Vault, Minter, Burner resources (keep as-is)
    
    // NEW: Withdrawal tracking
    access(all) event GUMWithdrawnFromWebsite(
        address: Address,
        amount: UFix64,
        withdrawalID: String
    )
    
    // NEW: Admin function for website withdrawals
    access(all) resource Admin {
        access(all) fun mintAndTransfer(
            recipient: Address,
            amount: UFix64,
            withdrawalID: String
        ) {
            // Mint GUM
            let minter = GUM.account.storage.borrow<&Minter>(...)
            let vault <- minter.mintTokens(amount: amount)
            
            // Send to user
            let recipientVault = getAccount(recipient)
                .capabilities.get<&{FungibleToken.Receiver}>(...)
                .borrow() ?? panic("No vault")
            
            recipientVault.deposit(from: <- vault)
            
            emit GUMWithdrawnFromWebsite(
                address: recipient,
                amount: amount,
                withdrawalID: withdrawalID
            )
        }
    }
}
```

---

## 🌐 Website Integration

### User Journey

#### Earning GUM (Website - Supabase)
```javascript
// pages/api/earn-gum.ts
export async function POST(req: Request) {
  const { userAddress, activityType } = await req.json();
  
  // Calculate reward
  const amount = getRewardAmount(activityType);
  
  // Update database
  await supabase.from('user_gum_balance').upsert({
    user_address: userAddress,
    balance: sql`balance + ${amount}`,
    total_earned: sql`total_earned + ${amount}`
  });
  
  await supabase.from('gum_earnings').insert({
    user_address: userAddress,
    amount,
    activity_type: activityType
  });
  
  return { success: true, newBalance: ... };
}
```

#### Withdrawing GUM (Website → Blockchain)
```javascript
// pages/api/withdraw-gum.ts
export async function POST(req: Request) {
  const { userAddress, amount } = await req.json();
  
  // 1. Check database balance
  const { data: user } = await supabase
    .from('user_gum_balance')
    .select('balance')
    .eq('user_address', userAddress)
    .single();
  
  if (user.balance < amount) {
    return { error: 'Insufficient balance' };
  }
  
  // 2. Create withdrawal record
  const { data: withdrawal } = await supabase
    .from('gum_withdrawals')
    .insert({
      user_address: userAddress,
      amount,
      status: 'pending'
    })
    .select()
    .single();
  
  // 3. Execute Flow transaction (admin signs)
  const txId = await fcl.mutate({
    cadence: MINT_AND_TRANSFER_TRANSACTION,
    args: (arg, t) => [
      arg(userAddress, t.Address),
      arg(amount.toFixed(8), t.UFix64),
      arg(withdrawal.id, t.String)
    ],
    authorizations: [adminAuthorization], // Your backend admin account
    limit: 1000
  });
  
  // 4. Update database
  await supabase.from('user_gum_balance').update({
    balance: sql`balance - ${amount}`
  }).eq('user_address', userAddress);
  
  await supabase.from('gum_withdrawals').update({
    tx_id: txId,
    status: 'completed',
    completed_at: new Date()
  }).eq('id', withdrawal.id);
  
  return { success: true, txId };
}
```

### UI Components
```typescript
// components/GUMBalance.tsx
export function GUMBalance({ userAddress }: { userAddress: string }) {
  const [balance, setBalance] = useState({ database: 0, wallet: 0 });
  
  // Database balance
  const { data: dbBalance } = useQuery('gum-db-balance', async () => {
    const res = await fetch(`/api/gum-balance?address=${userAddress}`);
    return res.json();
  });
  
  // Wallet balance (on-chain)
  const walletBalance = useGUMBalance(userAddress); // FCL query
  
  return (
    <div>
      <h3>Your GUM</h3>
      <p>Available to earn: {dbBalance?.balance || 0} GUM</p>
      <p>In wallet: {walletBalance || 0} GUM</p>
      
      <button onClick={() => withdrawGUM(dbBalance.balance)}>
        Withdraw to Wallet
      </button>
    </div>
  );
}
```

---

## 🎁 NFT Airdrops vs Website Icons

### Option 1: Website Icons/Badges (Database Only)
```sql
-- Achievement badges (no NFT, just database)
CREATE TABLE user_achievements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_address TEXT NOT NULL,
  achievement_type TEXT NOT NULL, -- 'early_adopter', '100_check_ins', etc.
  icon_url TEXT NOT NULL,
  earned_at TIMESTAMP DEFAULT NOW(),
  displayed BOOLEAN DEFAULT TRUE
);
```

**Pros:**
- ✅ No blockchain costs
- ✅ Instant
- ✅ Easy to manage
- ✅ Can have unlimited variations

**Cons:**
- ❌ Not "owned" on blockchain
- ❌ Can't trade/transfer
- ❌ No resale value
- ❌ Centralized (you control it)

**Use case:** Progress indicators, daily streaks, profile decorations

---

### Option 2: NFT Airdrops (On-Chain)
```cadence
// Achievement NFT Collection
access(all) contract FlunksAchievements: NonFungibleToken {
    access(all) resource NFT: NonFungibleToken.NFT {
        access(all) let id: UInt64
        access(all) let achievementType: String
        access(all) let earnedAt: UFix64
        access(all) let metadata: {String: String}
    }
    
    // Mint achievement NFT
    access(all) fun mintAchievement(
        recipient: Address,
        achievementType: String
    ) {
        let nft <- create NFT(
            id: self.totalSupply,
            achievementType: achievementType,
            earnedAt: getCurrentBlock().timestamp,
            metadata: getAchievementMetadata(achievementType)
        )
        
        // Send to user
        let recipientCollection = getAccount(recipient)
            .capabilities.get<&{NonFungibleToken.CollectionPublic}>(...)
            .borrow() ?? panic("No collection")
        
        recipientCollection.deposit(token: <- nft)
        self.totalSupply = self.totalSupply + 1
    }
}
```

**Pros:**
- ✅ True ownership on blockchain
- ✅ Tradeable/transferable
- ✅ Verifiable rarity
- ✅ Shows in all NFT marketplaces
- ✅ Permanent record

**Cons:**
- ❌ Gas costs (you pay to mint & send)
- ❌ User needs Flow wallet setup
- ❌ Slower (blockchain confirmation)
- ❌ More complex to manage

**Use case:** Milestone achievements, rare collectibles, status symbols

---

## 🆕 New Collection vs Existing Collection

### Option A: Use Existing Flunks Collection
```cadence
// Add achievement traits to existing Flunks
access(all) resource NFT {
    access(all) let id: UInt64
    // ... existing fields
    
    // NEW: Achievement badges
    access(self) var achievements: [String]
    
    access(all) fun addAchievement(achievement: String) {
        self.achievements.append(achievement)
    }
}
```

**Pros:**
- ✅ No new collection needed
- ✅ Users already have Flunks
- ✅ Achievements enhance existing NFTs
- ✅ No setup required

**Cons:**
- ❌ Requires contract upgrade
- ❌ Only for Flunks owners
- ❌ Can't trade achievements separately

---

### Option B: New Achievement Collection
```cadence
// Separate FlunksAchievements collection
access(all) contract FlunksAchievements: NonFungibleToken {
    // Completely separate from Flunks.cdc
    // Own NFTs, own metadata, own marketplace
}
```

**Pros:**
- ✅ Independent from Flunks
- ✅ Anyone can earn (not just Flunks holders)
- ✅ Tradeable separately
- ✅ Easier to manage

**Cons:**
- ❌ Requires new collection setup
- ❌ Users need to initialize new collection
- ❌ More storage overhead for users

---

## 🛠️ Setting Up a New Collection (It's Easy!)

### Step 1: Create Contract
```cadence
// FlunksAchievements.cdc
import NonFungibleToken from 0x1d7e57aa55817448
import MetadataViews from 0x1d7e57aa55817448

access(all) contract FlunksAchievements: NonFungibleToken {
    access(all) var totalSupply: UInt64
    
    access(all) let CollectionStoragePath: StoragePath
    access(all) let CollectionPublicPath: PublicPath
    access(all) let AdminStoragePath: StoragePath
    
    access(all) event Minted(id: UInt64, achievementType: String, recipient: Address)
    
    access(all) resource NFT: NonFungibleToken.NFT {
        access(all) let id: UInt64
        access(all) let achievementType: String
        access(all) let earnedAt: UFix64
        access(all) let metadata: {String: String}
        
        init(id: UInt64, achievementType: String, metadata: {String: String}) {
            self.id = id
            self.achievementType = achievementType
            self.earnedAt = getCurrentBlock().timestamp
            self.metadata = metadata
        }
        
        access(all) view fun getViews(): [Type] {
            return [Type<MetadataViews.Display>()]
        }
        
        access(all) fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.metadata["name"] ?? "Achievement",
                        description: self.metadata["description"] ?? "",
                        thumbnail: MetadataViews.HTTPFile(
                            url: self.metadata["image"] ?? ""
                        )
                    )
            }
            return nil
        }
        
        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <- FlunksAchievements.createEmptyCollection(nftType: Type<@NFT>())
        }
    }
    
    access(all) resource Collection: NonFungibleToken.Collection {
        access(all) var ownedNFTs: @{UInt64: {NonFungibleToken.NFT}}
        
        init() {
            self.ownedNFTs <- {}
        }
        
        // Standard collection functions...
        access(NonFungibleToken.Withdraw)
        fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT} {
            let token <- self.ownedNFTs.remove(key: withdrawID)!
            return <- token
        }
        
        access(all) fun deposit(token: @{NonFungibleToken.NFT}) {
            let nft <- token as! @NFT
            self.ownedNFTs[nft.id] <-! nft
        }
        
        access(all) view fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }
        
        access(all) view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}? {
            return &self.ownedNFTs[id]
        }
        
        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <- FlunksAchievements.createEmptyCollection(nftType: Type<@NFT>())
        }
    }
    
    access(all) fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection} {
        return <- create Collection()
    }
    
    access(all) resource Admin {
        access(all) fun mintAchievement(
            recipient: Address,
            achievementType: String,
            metadata: {String: String}
        ) {
            let nft <- create NFT(
                id: FlunksAchievements.totalSupply,
                achievementType: achievementType,
                metadata: metadata
            )
            
            let recipientCollection = getAccount(recipient)
                .capabilities.get<&{NonFungibleToken.CollectionPublic}>(
                    FlunksAchievements.CollectionPublicPath
                )
                .borrow()
                ?? panic("Could not borrow collection")
            
            let nftID = nft.id
            recipientCollection.deposit(token: <- nft)
            
            FlunksAchievements.totalSupply = FlunksAchievements.totalSupply + 1
            
            emit Minted(id: nftID, achievementType: achievementType, recipient: recipient)
        }
    }
    
    init() {
        self.totalSupply = 0
        
        self.CollectionStoragePath = /storage/FlunksAchievementsCollection
        self.CollectionPublicPath = /public/FlunksAchievementsCollection
        self.AdminStoragePath = /storage/FlunksAchievementsAdmin
        
        let admin <- create Admin()
        self.account.storage.save(<-admin, to: self.AdminStoragePath)
        
        let collection <- create Collection()
        self.account.storage.save(<-collection, to: self.CollectionStoragePath)
        
        let collectionCap = self.account.capabilities.storage.issue<&Collection>(
            self.CollectionStoragePath
        )
        self.account.capabilities.publish(collectionCap, at: self.CollectionPublicPath)
    }
}
```

### Step 2: Deploy (5 minutes)
```bash
# Deploy to testnet
flow accounts add-contract FlunksAchievements ./cadence/contracts/FlunksAchievements.cdc --network testnet

# Deploy to mainnet
flow accounts add-contract FlunksAchievements ./cadence/contracts/FlunksAchievements.cdc --network mainnet
```

### Step 3: Users Initialize Collection (One-time)
```cadence
// setup-achievements-collection.cdc
import FlunksAchievements from 0x...

transaction {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Check if already has collection
        if signer.storage.type(at: FlunksAchievements.CollectionStoragePath) != nil {
            return
        }
        
        // Create collection
        let collection <- FlunksAchievements.createEmptyCollection(
            nftType: Type<@FlunksAchievements.NFT>()
        )
        
        // Save it
        signer.storage.save(<-collection, to: FlunksAchievements.CollectionStoragePath)
        
        // Link public capability
        let cap = signer.capabilities.storage.issue<&FlunksAchievements.Collection>(
            FlunksAchievements.CollectionStoragePath
        )
        signer.capabilities.publish(cap, at: FlunksAchievements.CollectionPublicPath)
    }
}
```

---

## 💡 Recommended Hybrid Approach

### Database Icons (Most Achievements)
- Daily check-ins
- Profile milestones
- Activity streaks
- Social engagement

### NFT Airdrops (Special Achievements)
- First 100 users
- Completed full journey
- Community milestones
- Special events

### Example Achievement System
```typescript
// Achievement configuration
const ACHIEVEMENTS = {
  // Database only (instant, free)
  daily_streak_7: {
    type: 'database_icon',
    reward: { gum: 50 },
    icon: '/badges/streak-7.png'
  },
  
  profile_complete: {
    type: 'database_icon',
    reward: { gum: 25 },
    icon: '/badges/profile.png'
  },
  
  // NFT airdrop (special, valuable)
  early_adopter: {
    type: 'nft_airdrop',
    reward: { gum: 100, nft: 'early_adopter' },
    contract: 'FlunksAchievements',
    achievementType: 'EARLY_ADOPTER_2025'
  },
  
  community_champion: {
    type: 'nft_airdrop',
    reward: { gum: 500, nft: 'champion' },
    contract: 'FlunksAchievements',
    achievementType: 'COMMUNITY_CHAMPION'
  }
};
```

---

## 🚀 Next Steps

1. **Phase 1: Clean Up (This Week)**
   - Remove Staking.cdc and GUMStakingTracker.cdc
   - Simplify GUM.cdc contract
   - Update documentation

2. **Phase 2: Website Integration (This Week)**
   - Set up Supabase tables
   - Build GUM earning API endpoints
   - Create withdrawal system
   - Build UI components

3. **Phase 3: Achievement System (Next Week)**
   - Decide database vs NFT for each achievement
   - Create FlunksAchievements.cdc (if using NFTs)
   - Build achievement tracking system
   - Design icons/metadata

4. **Phase 4: Testing (Before Launch)**
   - Test GUM earning flows
   - Test withdrawal to wallet
   - Test achievement minting
   - Load testing

---

## ❓ Questions to Decide

1. **NFT Achievements**: Which achievements deserve NFTs vs icons?
2. **Collection**: New collection or extend Flunks?
3. **Costs**: Who pays for NFT minting? (You or users)
4. **Rarity**: Should achievements have limited supply?
5. **Trading**: Allow achievement NFT trading?

Let me know your preferences and I'll help implement! 🎯
