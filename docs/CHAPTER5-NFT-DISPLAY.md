# Chapter 5 NFT - Where It Shows Up

## 📍 Collection Details

### Contract Information
- **Contract Name**: `SemesterZero` (aka SemesterZero_Hackathon)
- **Mainnet Address**: `0x807c3d470888cc48` (same as mainnet-account)
- **NFT Resource**: `SemesterZero.Chapter5NFT`
- **Collection Type**: `SemesterZero.Chapter5Collection`

### Storage Paths
```cadence
StoragePath: /storage/SemesterZeroChapter5Collection
PublicPath: /public/SemesterZeroChapter5Collection
```

---

## 🎨 NFT Metadata

### What Users Will See
```json
{
  "name": "Paradise Motel",
  "description": "Awarded for completing both Slacker and Overachiever objectives in Chapter 5 of Flunks: Semester Zero",
  "achievement": "SLACKER_AND_OVERACHIEVER",
  "chapter": "5",
  "collection": "Flunks: Semester Zero",
  "rarity": "Legendary",
  "image": "https://storage.googleapis.com/flunks_public/nfts/chapter5-completion.png"
}
```

### NFT Type
- Implements `NonFungibleToken.NFT` standard
- Implements `MetadataViews.Display` for wallet display
- Each NFT has unique ID (sequential minting)

---

## 👛 Where NFTs Appear

### 1. Flow Wallets (Blocto, Lilico, etc.)
NFTs will show up under:
- **Collection Name**: "Flunks: Semester Zero"
- **Contract**: `A.807c3d470888cc48.SemesterZero`
- **Image**: The metadata image URL will display
- **Details**: Name, description, achievement type

### 2. Flowty Marketplace
**To list on Flowty:**

Users need to connect their wallet and select from their collections. The NFT will appear as:

- **Collection**: `Flunks: Semester Zero` 
- **Contract Address**: `0x807c3d470888cc48`
- **NFT Type**: `Chapter5NFT`

**⚠️ IMPORTANT**: Flowty needs to **index** the `SemesterZero` contract first. You may need to:
1. Contact Flowty support to add `SemesterZero` contract to their indexer
2. Provide contract address: `0x807c3d470888cc48`
3. Provide collection metadata

---

## 🔍 How Users Get the NFT

### Step 1: Claim GumDrop (Oct 31 - Nov 3)
When users click the pumpkin button, the transaction:
1. Creates `UserProfile` (with timezone)
2. Creates `Chapter5Collection` (empty, ready for NFT)
3. Marks GumDrop as eligible to claim

### Step 2: Complete Objectives
- **Slacker**: Enter `SLACKER` code → Supabase tracks it
- **Overachiever**: Complete Hidden Riff → Enter `CGAF` code → Supabase tracks it

### Step 3: Admin Airdrops (After Nov 3)
You run `bulk-chapter5-airdrop.sh` which:
1. Queries Supabase for eligible wallets (both codes entered)
2. Calls `registerSlackerCompletion()` on blockchain
3. Calls `registerOverachieverCompletion()` on blockchain
4. Calls `airdropChapter5NFT()` → NFT minted and deposited
5. NFT appears in user's wallet instantly!

---

## 📊 Querying NFTs

### Check if User Has NFT
```cadence
import SemesterZero from 0x807c3d470888cc48

access(all) fun main(userAddress: Address): [UInt64] {
  let collectionRef = getAccount(userAddress)
    .capabilities.get<&SemesterZero.Chapter5Collection>(
      SemesterZero.Chapter5CollectionPublicPath
    )
    .borrow()
    ?? panic("No Chapter 5 collection found")
  
  return collectionRef.getIDs()
}
```

### Get NFT Metadata
```cadence
import SemesterZero from 0x807c3d470888cc48
import MetadataViews from 0x631e88ae7f1d7c20

access(all) fun main(userAddress: Address, nftID: UInt64): MetadataViews.Display? {
  let collectionRef = getAccount(userAddress)
    .capabilities.get<&SemesterZero.Chapter5Collection>(
      SemesterZero.Chapter5CollectionPublicPath
    )
    .borrow()!
  
  let nft = collectionRef.borrowNFT(nftID)!
  return nft.resolveView(Type<MetadataViews.Display>()) as! MetadataViews.Display?
}
```

---

## 🖼️ Image Hosting

**Current Image URL**: 
```
https://storage.googleapis.com/flunks_public/nfts/chapter5-completion.png
```

**TODO**: Upload the actual Chapter 5 completion image to this URL!

Recommended image specs:
- **Size**: 1000x1000px or larger
- **Format**: PNG with transparency
- **Theme**: Slacker + Overachiever combo (maybe a trophy with "CGAF" attitude?)
- **Rarity**: Legendary feel (gold accents, special effects)

---

## 📈 Collection Stats

### Total Minted
```bash
flow scripts execute <<'EOF'
import SemesterZero from 0x807c3d470888cc48

access(all) fun main(): {String: UInt64} {
  return SemesterZero.getStats()
}
EOF
```

Returns:
```json
{
  "totalGumDrops": 150,
  "totalChapter5Completions": 42,
  "totalChapter5NFTs": 42
}
```

---

## 🎯 Next Steps

1. **Upload Chapter 5 Image**: Create and upload the legendary completion badge
2. **Test Airdrop**: Run a test airdrop to verify wallet display
3. **Contact Flowty**: Get `SemesterZero` contract indexed for marketplace listings
4. **Announce Rarity**: Let community know this is a Legendary achievement NFT

---

## ❓ FAQ

**Q: Can users have multiple Chapter 5 NFTs?**  
A: No. The contract checks `nftAirdropped` flag - one per wallet max.

**Q: Will it show up in all Flow wallets?**  
A: Yes, any wallet that implements the `NonFungibleToken` standard will display it.

**Q: Can users transfer/sell it?**  
A: Yes! It's a standard NFT. Users can list on Flowty, trade peer-to-peer, etc.

**Q: What if someone doesn't claim the GumDrop but completes both objectives?**  
A: They won't have the `Chapter5Collection` set up, so the airdrop will fail. The bulk script will warn you. They need to either claim GumDrop or manually run `setup-chapter5-collection.cdc`.

**Q: Where does the image get hosted?**  
A: The contract points to `storage.googleapis.com/flunks_public/nfts/chapter5-completion.png` - make sure to upload the actual image there before airdrops!
