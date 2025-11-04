#!/bin/bash
# =====================================================
# BULK CHAPTER 5 NFT AIRDROP
# =====================================================
# Run this AFTER Halloween window closes to airdrop
# NFTs to all users who completed BOTH objectives:
# 1. Entered SLACKER code (Slacker objective)
# 2. Entered CGAF code from Hidden Riff (Overachiever)
# =====================================================

set -e

NETWORK="mainnet"
ADMIN_ADDRESS="0x807c3d470888cc48"
ADMIN_KEY="mainnet-account"

echo "🎯 Chapter 5 NFT Bulk Airdrop"
echo "=============================="
echo ""

# Step 1: Get eligible wallets from Supabase
echo "📊 Fetching eligible wallets from Supabase..."
ELIGIBLE_WALLETS=$(flow scripts execute <<'EOF'
import SemesterZero from 0x807c3d470888cc48

// NOTE: Replace this with actual Supabase query results
// For now, this is a placeholder that shows the pattern

access(all) fun main(): [Address] {
  // In production, you'd call your Supabase RPC function
  // and return the list of eligible wallet addresses
  return []
}
EOF
)

echo "Found eligible wallets:"
echo "$ELIGIBLE_WALLETS"
echo ""

# Step 2: For each wallet, register completions and airdrop
echo "🚀 Starting bulk airdrop process..."
echo ""

# Example wallet array (replace with actual Supabase results)
WALLETS=(
  # "0x123abc..."
  # "0x456def..."
)

for WALLET in "${WALLETS[@]}"; do
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Processing: $WALLET"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  # Register Slacker completion
  echo "  ✅ Registering Slacker completion..."
  flow transactions send \
    ./cadence/transactions/register-slacker-completion.cdc \
    $WALLET \
    --network=$NETWORK \
    --signer=$ADMIN_KEY \
    --gas-limit=1000
  
  # Register Overachiever completion
  echo "  ✅ Registering Overachiever completion..."
  flow transactions send \
    ./cadence/transactions/register-overachiever-completion.cdc \
    $WALLET \
    --network=$NETWORK \
    --signer=$ADMIN_KEY \
    --gas-limit=1000
  
  # Check if user has Chapter 5 collection setup
  HAS_COLLECTION=$(flow scripts execute <<EOF
import SemesterZero from 0x807c3d470888cc48

access(all) fun main(userAddress: Address): Bool {
  return getAccount(userAddress)
    .capabilities.get<&SemesterZero.Chapter5Collection>(SemesterZero.Chapter5CollectionPublicPath)
    .check()
}
EOF
  $WALLET --network=$NETWORK)
  
  if [ "$HAS_COLLECTION" = "true" ]; then
    # Airdrop the NFT
    echo "  🎁 Airdropping Chapter 5 NFT..."
    TX_ID=$(flow transactions send \
      ./cadence/transactions/airdrop-chapter5-nft.cdc \
      $WALLET \
      --network=$NETWORK \
      --signer=$ADMIN_KEY \
      --gas-limit=1000 \
      | grep "ID" | awk '{print $2}')
    
    echo "  ✅ NFT Airdropped! TX: $TX_ID"
  else
    echo "  ⚠️  User needs to setup Chapter 5 collection first"
    echo "  💡 They can do this by claiming a GumDrop with timezone"
  fi
  
  echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Bulk airdrop process complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
