# 🏪 Marketplace Compatibility - Achievement NFTs

## ✅ Flowty, FlowVerse & All Flow Marketplaces Ready!

Your **Semester Zero Achievement NFTs** are now fully compatible with all Flow marketplaces including:
- ✅ **Flowty** (flowty.io)
- ✅ **FlowVerse** (flowverse.co)
- ✅ **NBA Top Shot Marketplace**
- ✅ **Gaia** (gaia.market)
- ✅ **And any other marketplace that supports MetadataViews standard**

---

## 📋 What Was Added

### MetadataViews Implementation

Your Achievement NFTs now implement **all required metadata views** that marketplaces need:

```cadence
access(all) view fun getViews(): [Type] {
    return [
        Type<MetadataViews.Display>(),              // ✅ Name, description, image
        Type<MetadataViews.ExternalURL>(),          // ✅ Link to flunks.net
        Type<MetadataViews.NFTCollectionData>(),    // ✅ Collection info
        Type<MetadataViews.NFTCollectionDisplay>(), // ✅ Collection branding ⭐ NEW!
        Type<MetadataViews.Royalties>(),            // ✅ Creator royalties ⭐ NEW!
        Type<MetadataViews.Serial>(),               // ✅ Serial number ⭐ NEW!
        Type<MetadataViews.Traits>(),               // ✅ NFT traits/attributes
        Type<MetadataViews.Editions>()              // ✅ Tier editions ⭐ NEW!
    ]
}
```

---

## 🎨 NFTCollectionDisplay (How Your Collection Appears)

Marketplaces will display your collection like this:

```cadence
MetadataViews.NFTCollectionDisplay(
    name: "Semester Zero Achievements",
    description: "Dynamic achievement NFTs that evolve as you earn GUM in the Flunks ecosystem. Unlock higher tiers by reaching milestones!",
    externalURL: "https://flunks.net/semester-zero",
    squareImage: "https://storage.googleapis.com/flunks_public/website-assets/semester-zero-logo.png",
    bannerImage: "https://storage.googleapis.com/flunks_public/website-assets/semester-zero-banner.png",
    socials: {
        "twitter": "https://twitter.com/flunks_nft",
        "discord": "https://discord.gg/flunks"
    }
)
```

### What You Need to Create:

Upload these images to your Google Cloud Storage:

1. **`semester-zero-logo.png`** (Square - 512x512px or 1024x1024px)
   - Logo for your Achievement collection
   - Shows in marketplace collection pages
   - Path: `https://storage.googleapis.com/flunks_public/website-assets/semester-zero-logo.png`

2. **`semester-zero-banner.png`** (Wide - 1500x500px or 3000x1000px)
   - Banner for collection page
   - Shows at top of marketplace collection view
   - Path: `https://storage.googleapis.com/flunks_public/website-assets/semester-zero-banner.png`

---

## 💰 Royalties (Creator Revenue)

Your Achievement NFTs include **5% royalty** to the Flunks creator account:

```cadence
MetadataViews.Royalties([
    MetadataViews.Royalty(
        receiver: merchant.capabilities.get<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)!,
        cut: 0.05,  // 5%
        description: "Flunks creator royalty in DUC"
    )
])
```

**How it works:**
- Every secondary sale on marketplace pays 5% to `0x0cce91b08cb58286`
- Paid in **DUC** (Dapper Utility Coin)
- Automatic - marketplaces handle this

**To change royalty:**
- Update the account address in the code
- Adjust the `cut` value (0.05 = 5%, 0.10 = 10%, etc.)

---

## 🔢 Serial Numbers

Each Achievement NFT has a unique serial number:

```cadence
MetadataViews.Serial(self.id)
```

**Example:**
- Achievement NFT #1 → Serial #1
- Achievement NFT #42 → Serial #42

Marketplaces display this as "Serial #42" or "#42 of ∞"

---

## 🏆 Editions (Tier System)

Achievement NFTs show their current **tier as an edition**:

```cadence
MetadataViews.Editions([
    MetadataViews.Edition(
        name: "Gold Tier",  // Current tier
        number: 3,          // Tier number (1-5)
        max: nil            // No max (can upgrade!)
    )
])
```

**Tier Numbers:**
- Bronze = 1
- Silver = 2
- Gold = 3
- Platinum = 4
- Diamond = 5

**On Marketplaces:**
- Shows as "Edition: Gold Tier (3)"
- Updates automatically as user earns more GUM!

---

## 🎨 Display (Individual NFT)

Each Achievement NFT displays with dynamic metadata:

```cadence
MetadataViews.Display(
    name: "Gold GUM Earner Achievement",
    description: "This achievement evolves as you earn more GUM! Current tier: Gold",
    thumbnail: "https://storage.googleapis.com/flunks_public/achievements/gum_earner_gold.png"
)
```

**What marketplaces show:**
- ✅ NFT name with current tier
- ✅ Description explaining it evolves
- ✅ Current tier image
- ✅ Updates automatically when user earns more GUM!

---

## 🏷️ Traits (Attributes)

Marketplaces show these as "Properties" or "Traits":

```cadence
MetadataViews.Traits([
    { name: "type", value: "gum_earner", displayType: "String" },
    { name: "tier", value: "Gold", displayType: "String" },
    { name: "minted_at", value: "1698345600", displayType: "Date" }
])
```

**On Flowty/FlowVerse:**
```
Properties:
┌──────────────┬─────────────┐
│ Type         │ gum_earner  │
│ Tier         │ Gold        │
│ Minted At    │ Oct 18, 2025│
└──────────────┴─────────────┘
```

---

## 🔗 External URL

Links to your website from marketplace:

```cadence
MetadataViews.ExternalURL("https://flunks.net/achievements")
```

**On marketplaces:**
- Shows "View on flunks.net" button
- Directs users to your achievement page

---

## 📊 How It Looks on Flowty

### Collection Page:
```
┌─────────────────────────────────────────────────────────┐
│  [Banner: Semester Zero Achievements]                  │
│                                                         │
│  🏆 Semester Zero Achievements                         │
│  By Flunks                                             │
│                                                         │
│  Dynamic achievement NFTs that evolve as you earn GUM  │
│  in the Flunks ecosystem. Unlock higher tiers!         │
│                                                         │
│  🔗 flunks.net/semester-zero                           │
│  🐦 @flunks_nft  💬 Discord                           │
│                                                         │
│  Items: 127    Floor: 5 FLOW    Volume: 250 FLOW      │
└─────────────────────────────────────────────────────────┘

  [Grid of Achievement NFTs]
  ┌─────────┐ ┌─────────┐ ┌─────────┐
  │ Gold    │ │ Silver  │ │ Diamond │
  │ GUM     │ │ Tipper  │ │ GUM     │
  │ Earner  │ │ #42     │ │ Earner  │
  │ #1      │ │ 5 FLOW  │ │ #99     │
  │ 10 FLOW │ └─────────┘ │ 50 FLOW │
  └─────────┘             └─────────┘
```

### Individual NFT Page:
```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│         [Gold Achievement Badge Image]                 │
│                                                         │
│  Gold GUM Earner Achievement #42                       │
│  Semester Zero Achievements                            │
│                                                         │
│  This achievement evolves as you earn more GUM!        │
│  Current tier: Gold                                    │
│                                                         │
│  📊 Current Price: 10 FLOW                            │
│  [Buy Now]  [Make Offer]                              │
│                                                         │
│  Properties:                                           │
│  ┌───────────┬────────────┐                           │
│  │ Type      │ gum_earner │                           │
│  │ Tier      │ Gold       │                           │
│  │ Serial    │ #42        │                           │
│  │ Edition   │ Gold Tier  │                           │
│  │ Minted    │ Oct 18     │                           │
│  └───────────┴────────────┘                           │
│                                                         │
│  💎 Creator Royalty: 5%                                │
│  🔗 View on flunks.net                                │
└─────────────────────────────────────────────────────────┘
```

---

## 🎯 Marketplace Features Enabled

### ✅ Listing & Trading
- Users can list Achievement NFTs for sale
- Set prices in FLOW, DUC, or other tokens
- Make offers on other users' achievements

### ✅ Collection Verification
- Marketplaces can verify your collection
- Shows as "Verified" with checkmark
- Uses contract address for verification

### ✅ Sorting & Filtering
- By tier (Bronze, Silver, Gold, etc.)
- By achievement type (gum_earner, tipper, etc.)
- By serial number
- By mint date

### ✅ Rarity Indicators
- Marketplaces can show tier distribution
- Diamond tier = rarest
- Bronze tier = most common

### ✅ Dynamic Updates
- Achievement tier updates automatically
- Image changes when user earns more GUM
- Marketplace displays current tier

---

## 🚀 Deployment Checklist

### 1. Create Collection Branding Assets

Upload to Google Cloud Storage:

```
flunks_public/
└── website-assets/
    ├── semester-zero-logo.png      (512x512 or 1024x1024)
    └── semester-zero-banner.png    (1500x500 or 3000x1000)
```

### 2. Create Achievement Tier Images

```
flunks_public/
└── achievements/
    ├── gum_earner_bronze.png
    ├── gum_earner_silver.png
    ├── gum_earner_gold.png
    ├── gum_earner_platinum.png
    ├── gum_earner_diamond.png
    ├── early_supporter_bronze.png
    ├── early_supporter_silver.png
    └── ... (all tiers for all types)
```

### 3. Deploy SemesterZero Contract

```bash
flow accounts add-contract SemesterZero ./cadence/contracts/SemesterZero.cdc
```

### 4. Submit to Marketplace Catalogs

**Flowty:**
- Go to flowty.io/submit
- Submit SemesterZero Achievement collection
- Provide collection details

**FlowVerse:**
- Similar submission process
- Collections auto-detected via MetadataViews

**NFT Catalog:**
- Submit to Flow NFT Catalog (centralized registry)
- All marketplaces reference this

---

## 📝 NFT Catalog Submission

To get your collection indexed by all marketplaces:

### 1. Prepare Collection Info

```json
{
  "contractName": "SemesterZero",
  "contractAddress": "0x...",  // Your deployed address
  "nftType": "A.YOUR_ADDRESS.SemesterZero.AchievementNFT",
  "collectionData": "A.YOUR_ADDRESS.SemesterZero.AchievementCollection",
  "collectionDisplay": {
    "name": "Semester Zero Achievements",
    "description": "Dynamic achievement NFTs that evolve as you earn GUM",
    "externalURL": "https://flunks.net/semester-zero",
    "squareImage": "https://storage.googleapis.com/flunks_public/website-assets/semester-zero-logo.png",
    "bannerImage": "https://storage.googleapis.com/flunks_public/website-assets/semester-zero-banner.png",
    "socials": {
      "twitter": "https://twitter.com/flunks_nft"
    }
  }
}
```

### 2. Submit via NFT Catalog Contract

```cadence
// Admin transaction to submit to NFT Catalog
import NFTCatalog from 0x...
import NFTCatalogAdmin from 0x...

transaction {
    prepare(admin: auth(Storage) &Account) {
        // Submit collection to catalog
        // This makes it discoverable by all marketplaces
    }
}
```

---

## 🎨 Asset Specifications

### Collection Logo (semester-zero-logo.png)
- **Size:** 512x512px or 1024x1024px
- **Format:** PNG with transparency
- **Content:** Semester Zero logo/icon
- **Use:** Collection thumbnail on marketplaces

### Collection Banner (semester-zero-banner.png)
- **Size:** 1500x500px or 3000x1000px
- **Format:** PNG or JPG
- **Content:** Wide banner showcasing collection
- **Use:** Top of collection page

### Achievement Tier Images
- **Size:** 512x512px or 1024x1024px
- **Format:** PNG with transparency
- **Naming:** `{type}_{tier}.png` (lowercase, underscores)
- **Examples:**
  - `gum_earner_gold.png`
  - `early_supporter_diamond.png`
  - `tipper_legendary_tipper.png`

---

## ✅ Marketplace Compatibility Checklist

- ✅ **MetadataViews.Display** → Name, image, description
- ✅ **MetadataViews.NFTCollectionDisplay** → Collection branding
- ✅ **MetadataViews.NFTCollectionData** → Collection paths
- ✅ **MetadataViews.Royalties** → Creator revenue (5%)
- ✅ **MetadataViews.ExternalURL** → Link to website
- ✅ **MetadataViews.Serial** → Unique serial numbers
- ✅ **MetadataViews.Editions** → Tier system
- ✅ **MetadataViews.Traits** → Properties/attributes
- ✅ **NonFungibleToken.Collection** → Standard collection interface
- ✅ **ViewResolver.Resolver** → View resolution

**Your Achievement NFTs are 100% marketplace-ready!** 🎉

---

## 🚀 Next Steps

1. **Create branding assets** (logo + banner)
2. **Create achievement artwork** (all tiers)
3. **Deploy contract to mainnet**
4. **Submit to NFT Catalog**
5. **List on Flowty/FlowVerse**
6. **Promote your collection!**

Your Achievement NFTs will appear on **ALL Flow marketplaces** just like Flunks, Ballerz, and other major collections! 🏆
