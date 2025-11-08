# Flunks: Semester Zero - NFT Token List Registration Guide

## 🎯 The Problem

The Flow NFT token list (now managed by Fixes.World) expects collections to have resources named:
- `NFT` (not `Chapter5NFT`)
- `Collection` (not `Chapter5Collection`)

Your current `SemesterZero_Hackathon.cdc` contract uses `Chapter5NFT` and `Chapter5Collection`, which is why it's not showing up in the token list search.

## ✅ Solution: Wrapper Contract (Recommended)

Deploy a **wrapper contract** that provides standard names without breaking existing NFT holders.

### How It Works

```
FlunksSemesterZero.cdc (NEW - Token List Compatible)
    ↓ wraps
SemesterZero_Hackathon.cdc (EXISTING - Keeps working)
    ↓ contains
Chapter5NFT (your actual NFTs - unchanged)
```

### Benefits

✅ **No breaking changes** - Existing NFT holders keep their tokens  
✅ **Token list compatible** - Uses standard `NFT` and `Collection` names  
✅ **Clean separation** - Wrapper is only for discovery, not storage  
✅ **Backward compatible** - Chapter 5 airdrops still work exactly the same

---

## 📦 Files Created

### 1. **Wrapper Contract**
`cadence/contracts/FlunksSemesterZero.cdc`

- Provides standard `NFT` and `Collection` resource names
- Wraps your existing `Chapter5NFT` resources
- Implements all required MetadataViews
- Ready for NFT token list registration

### 2. **Deployment Script**
`scripts/deploy-semester-zero-wrapper.sh`

- Deploys the wrapper contract to mainnet
- Provides registration instructions

---

## 🚀 Deployment Steps

### Step 1: Deploy Wrapper Contract

```bash
cd /Users/jeremy/Desktop/flunks.flow
./scripts/deploy-semester-zero-wrapper.sh
```

This will:
- Deploy `FlunksSemesterZero.cdc` to `0xce9dd43888d99574`
- Keep your existing `SemesterZero` contract unchanged
- Make the collection discoverable with standard names

### Step 2: Submit to Fixes.World Token List

The Flow NFT token list is now managed by **Fixes.World**.

**📋 Resources:**
- Token List Site: https://token-list.fixes.world
- GitHub Repo: https://github.com/fixes-world/token-list-jsons
- API Endpoint: https://token-list.fixes.world/api/nft-list/

**Create a PR to:** https://github.com/fixes-world/token-list-jsons

**Add file:** `jsons/nft/FlunksSemesterZero.json`

```json
{
  "contractName": "FlunksSemesterZero",
  "contractAddress": "0xce9dd43888d99574",
  "path": {
    "storage": "FlunksSemesterZeroCollection",
    "public": "FlunksSemesterZeroCollection"
  },
  "evmAddress": null,
  "flowAddress": "0xce9dd43888d99574",
  "tags": ["nft", "gaming", "achievement"],
  "identity": {
    "name": "Flunks: Semester Zero",
    "description": "Exclusive NFTs rewarding slackers and overachievers who completed Chapter 5 challenges in Flunks: Semester Zero.",
    "website": "https://flunks.io",
    "twitter": "https://twitter.com/flunksnft"
  },
  "display": {
    "name": "Flunks: Semester Zero",
    "description": "Exclusive NFTs from Semester Zero - Chapter 5 completion rewards",
    "thumbnail": "https://storage.googleapis.com/flunks_public/images/semesterzero.png",
    "banner": "https://storage.googleapis.com/flunks_public/images/banner.png"
  },
  "reviewStatus": 0
}
```

**Review Status Levels:**
- `0` - All (unreviewed)
- `1` - Reviewed by Reviewer
- `2` - Managed by Reviewer
- `3` - Verified by Reviewer
- `4` - Featured by Reviewer
- `5` - Blocked by Reviewer

### Step 3: Wait for Approval

Once your PR is merged and reviewed:
- ✅ Collection appears in Flow wallet NFT search
- ✅ Users can click "Add NFT" and find "Flunks: Semester Zero"
- ✅ Collection shows up on token-list.fixes.world
- ✅ Collection indexed by wallets and marketplaces

---

## ⚡ Alternative: Direct Contract Rename (Breaking Change)

If you want to rename the existing contract resources, you would need to:

1. **Create new contract** with `NFT` and `Collection` names
2. **Migrate all existing NFTs** to new collection
3. **Update all airdrops** to use new contract
4. **Notify all holders** to migrate their NFTs

**❌ Not recommended** - Too disruptive for existing NFT holders

---

## 🧪 Testing

### Test 1: Verify Contract Deployment

After deploying the wrapper contract, test that MetadataViews work:

```bash
flow scripts execute <<'EOF'
import FlunksSemesterZero from 0xce9dd43888d99574
import MetadataViews from 0x1d7e57aa55817448

access(all) fun main(): AnyStruct {
    let views = FlunksSemesterZero.getContractViews(resourceType: nil)
    
    let collectionDisplay = FlunksSemesterZero.resolveContractView(
        resourceType: nil,
        viewType: Type<MetadataViews.NFTCollectionDisplay>()
    ) as! MetadataViews.NFTCollectionDisplay?
    
    return {
        "views": views,
        "name": collectionDisplay?.name,
        "description": collectionDisplay?.description
    }
}
EOF
```

Expected output:
```
{
  "views": [Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>()],
  "name": "Flunks: Semester Zero",
  "description": "Exclusive NFTs from Flunks: Semester Zero..."
}
```

### Test 2: Check Token List API

Once your PR is merged, verify it appears in the API:

```bash
curl "https://token-list.fixes.world/api/nft-list/?filter=0&page=1&limit=100" | jq '.[] | select(.contractName == "FlunksSemesterZero")'
```

Or search for it:
```bash
curl "https://token-list.fixes.world/api/nft-list/?filter=0" | jq '.[] | select(.identity.name | contains("Semester Zero"))'
```

---

## 📊 Status

- ✅ Wrapper contract created
- ✅ Deployment script ready
- ⏳ Need to deploy to mainnet
- ⏳ Need to submit Fixes.World PR
- ⏳ Wait for approval

---

## 🎉 After Token List Registration

Once approved and indexed by Fixes.World, users will see:

**In Flow Wallet:**
```
Search NFTs: "Flunks" or "Semester Zero"
  → Flunks: Semester Zero
    [Add to My NFTs]
```

**In your wallet after claiming:**
```
NFTs
  → Flunks Community (3 Collectibles)
  → 2 Collectibles  
  → Flunks: Semester Zero (1 Collectible)  ← Shows up in search!
```

**On token-list.fixes.world:**
- Listed in NFT section
- Searchable by name
- Shows collection metadata
- Review status displayed

---

## ❓ FAQ

**Q: Will this affect existing Chapter 5 NFT holders?**  
A: No! The wrapper doesn't touch existing NFTs. It's only for discovery.

**Q: Do I need to update the airdrop system?**  
A: No! Continue using `SemesterZero.airdropChapter5NFT()` exactly as before.

**Q: Can users still see their NFTs in Flow wallet?**  
A: Yes! They show up now (as you showed in screenshot). This just makes them **searchable**.

**Q: How long does Fixes.World approval take?**  
A: Usually 1-2 weeks for PR review. You can request expedited review in their Discord.

**Q: What's the difference between review status levels?**  
A: Status 0 (unreviewed) is enough to appear in search. Higher levels (1-4) give better visibility and trust indicators.

---

## 🔗 Resources

- Fixes.World Token List: https://token-list.fixes.world
- GitHub Repo: https://github.com/fixes-world/token-list-jsons
- How to Use Guide: https://token-list.fixes.world/#how-to-use
- API Documentation: https://github.com/fixes-world/token-list#api-reference
- NFT Metadata Standard: https://github.com/onflow/flow-nft/blob/master/contracts/MetadataViews.cdc

---

**Ready to deploy?**

```bash
./scripts/deploy-semester-zero-wrapper.sh
```
