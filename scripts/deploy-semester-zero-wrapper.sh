#!/bin/bash
# Deploy FlunksSemesterZero wrapper contract and register with NFT token list

set -e

NETWORK="mainnet"
ACCOUNT="semester-zero-account"
CONTRACT_ADDRESS="0xce9dd43888d99574"

echo "🚀 Deploying Flunks: Semester Zero Wrapper Contract"
echo "=================================================="
echo ""
echo "This wrapper contract provides standard NFT/Collection names"
echo "required by the Flow NFT token list."
echo ""

# Step 1: Deploy the wrapper contract
echo "📝 Step 1: Deploying FlunksSemesterZero.cdc..."
echo ""

flow accounts add-contract FlunksSemesterZero \
  ./cadence/contracts/FlunksSemesterZero.cdc \
  --network=$NETWORK \
  --signer=$ACCOUNT

echo ""
echo "✅ Wrapper contract deployed at: $CONTRACT_ADDRESS"
echo ""

# Step 2: Instructions for Fixes.World registration
echo "📝 Step 2: Register with Fixes.World Token List"
echo ""
echo "⚠️  Token list registration is now managed by Fixes.World"
echo ""
echo "Next steps:"
echo ""
echo "1. Create PR to: https://github.com/fixes-world/token-list-jsons"
echo ""
echo "2. Add file: jsons/nft/FlunksSemesterZero.json"
echo ""
echo "3. Use this JSON template:"
echo ""
cat <<'TEMPLATE'
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
    "description": "Exclusive NFTs rewarding slackers and overachievers who completed Chapter 5 challenges.",
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
TEMPLATE
echo ""
echo "4. After PR is merged, verify at: https://token-list.fixes.world"
echo ""
echo "5. Check API: curl 'https://token-list.fixes.world/api/nft-list/?filter=0' | jq '.[] | select(.contractName == \"FlunksSemesterZero\")'"
echo ""
echo "✨ Done! Wrapper contract is live and ready for token list inclusion."
