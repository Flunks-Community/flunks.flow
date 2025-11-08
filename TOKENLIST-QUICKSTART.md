# Quick Guide: Register Flunks Semester Zero on Token List

## 🎯 Goal
Get "Flunks: Semester Zero" to show up when users search for NFTs in Flow wallets.

## 📋 What You Need to Do

### 1. Deploy Wrapper Contract (10 minutes)

```bash
cd ~/Desktop/flunks.flow
./scripts/deploy-semester-zero-wrapper.sh
```

This deploys `FlunksSemesterZero.cdc` which wraps your existing `Chapter5NFT` with standard naming.

### 2. Submit to Fixes.World (5 minutes)

**Fork and clone:** https://github.com/fixes-world/token-list-jsons

```bash
git clone https://github.com/YOUR_USERNAME/token-list-jsons
cd token-list-jsons
```

**Copy the JSON file:**
```bash
cp ~/Desktop/flunks.flow/FlunksSemesterZero.json jsons/nft/
```

**Create PR:**
```bash
git add jsons/nft/FlunksSemesterZero.json
git commit -m "Add Flunks: Semester Zero NFT collection"
git push
```

Then create PR on GitHub with description:
```
Adding Flunks: Semester Zero collection

Contract: FlunksSemesterZero at 0xce9dd43888d99574
Collection for Chapter 5 completion NFTs from Flunks: Semester Zero game

- Standard NFT/Collection naming ✅
- Full MetadataViews support ✅
- Live on mainnet ✅
```

### 3. Wait for Approval (~1-2 weeks)

Once merged, your collection will:
- ✅ Appear in token-list.fixes.world
- ✅ Be searchable in Flow wallets
- ✅ Show up in NFT discovery tools

## 🧪 Test After Deployment

**Verify contract:**
```bash
flow scripts execute <<'EOF'
import FlunksSemesterZero from 0xce9dd43888d99574
import MetadataViews from 0x1d7e57aa55817448

access(all) fun main(): String {
    let display = FlunksSemesterZero.resolveContractView(
        resourceType: nil,
        viewType: Type<MetadataViews.NFTCollectionDisplay>()
    ) as! MetadataViews.NFTCollectionDisplay?
    
    return display?.name ?? "Not found"
}
EOF
```

Expected: `"Flunks: Semester Zero"`

**Check token list API (after PR merge):**
```bash
curl "https://token-list.fixes.world/api/nft-list/?filter=0" | \
  jq '.[] | select(.contractName == "FlunksSemesterZero")'
```

## 📝 Files Involved

- `cadence/contracts/FlunksSemesterZero.cdc` - Wrapper contract
- `scripts/deploy-semester-zero-wrapper.sh` - Deployment script
- `FlunksSemesterZero.json` - Token list metadata (for PR)
- `docs/REGISTER-NFT-LIST.md` - Full documentation

## ⚡ Quick Links

- Token List Site: https://token-list.fixes.world
- GitHub Repo: https://github.com/fixes-world/token-list-jsons
- Full Docs: `docs/REGISTER-NFT-LIST.md`

---

**Ready?** Run: `./scripts/deploy-semester-zero-wrapper.sh`
