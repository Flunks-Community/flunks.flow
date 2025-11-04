#!/bin/bash
# =====================================================
# TEST CHAPTER 5 NFT AIRDROP SYSTEM
# =====================================================
# This script tests the full Chapter 5 flow end-to-end
# =====================================================

set -e

echo "🧪 Chapter 5 NFT Airdrop Test"
echo "=============================="
echo ""

# Configuration
NETWORK="testnet"  # Use testnet for testing
TEST_WALLET="0x01cf0e2f2f715450"  # Replace with your test wallet
ADMIN_ACCOUNT="Flunks2.0"

echo "📋 Test Checklist:"
echo "1. ✅ Supabase: access_code_discoveries table exists"
echo "2. ✅ Supabase: get_chapter5_completions() function exists"
echo "3. ⏳ Contract: SemesterZero deployed with latest changes"
echo "4. ⏳ Test wallet has both SLACKER and CGAF codes in Supabase"
echo "5. ⏳ Test wallet has Chapter5Collection set up"
echo ""

# ========================================
# STEP 1: Verify Contract Deployment
# ========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 1: Check if contract is deployed"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

CONTRACT_EXISTS=$(flow accounts get $ADMIN_ACCOUNT --network=$NETWORK 2>/dev/null | grep -c "SemesterZero" || echo "0")

if [ "$CONTRACT_EXISTS" = "0" ]; then
  echo "❌ SemesterZero contract NOT deployed to $NETWORK"
  echo ""
  echo "💡 To deploy:"
  echo "   flow project deploy --network=$NETWORK"
  exit 1
else
  echo "✅ SemesterZero contract is deployed"
fi

echo ""

# ========================================
# STEP 2: Setup Test Data in Supabase
# ========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 2: Add test data to Supabase"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📝 Manually insert test data into Supabase:"
echo ""
echo "INSERT INTO access_code_discoveries (wallet_address, code_entered, success)"
echo "VALUES "
echo "  ('$TEST_WALLET', 'SLACKER', true),"
echo "  ('$TEST_WALLET', 'CGAF', true);"
echo ""
read -p "Press Enter once you've added the test data to Supabase..."
echo ""

# ========================================
# STEP 3: Setup Chapter 5 Collection
# ========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 3: Setup Chapter 5 Collection"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if collection already exists
HAS_COLLECTION=$(flow scripts execute <<EOF
import SemesterZero from 0xb97ea2274b0ae5d2

access(all) fun main(userAddress: Address): Bool {
  return getAccount(userAddress)
    .capabilities.get<&SemesterZero.Chapter5Collection>(SemesterZero.Chapter5CollectionPublicPath)
    .check()
}
EOF
$TEST_WALLET --network=$NETWORK 2>/dev/null || echo "false")

if [ "$HAS_COLLECTION" = "true" ]; then
  echo "✅ Test wallet already has Chapter 5 collection"
else
  echo "📦 Creating Chapter 5 collection for test wallet..."
  
  # User needs to run this themselves (can't set up someone else's account)
  echo ""
  echo "💡 Test wallet needs to run:"
  echo "   flow transactions send ./cadence/transactions/setup-chapter5-collection.cdc \\"
  echo "     --network=$NETWORK \\"
  echo "     --signer=your-test-account"
  echo ""
  read -p "Press Enter once collection is set up..."
fi

echo ""

# ========================================
# STEP 4: Register Slacker Completion
# ========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 4: Register Slacker Completion"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "📝 Calling registerSlackerCompletion()..."
flow transactions send \
  ./cadence/transactions/register-slacker-completion.cdc \
  $TEST_WALLET \
  --network=$NETWORK \
  --signer=$ADMIN_ACCOUNT \
  --gas-limit=1000

echo "✅ Slacker completion registered"
echo ""

# ========================================
# STEP 5: Register Overachiever Completion
# ========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 5: Register Overachiever Completion"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "📝 Calling registerOverachieverCompletion()..."
flow transactions send \
  ./cadence/transactions/register-overachiever-completion.cdc \
  $TEST_WALLET \
  --network=$NETWORK \
  --signer=$ADMIN_ACCOUNT \
  --gas-limit=1000

echo "✅ Overachiever completion registered"
echo ""

# ========================================
# STEP 6: Check Eligibility
# ========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 6: Check NFT Eligibility"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ELIGIBLE=$(flow scripts execute <<EOF
import SemesterZero from 0xb97ea2274b0ae5d2

access(all) fun main(userAddress: Address): Bool {
  return SemesterZero.isEligibleForChapter5NFT(userAddress: userAddress)
}
EOF
$TEST_WALLET --network=$NETWORK)

if [ "$ELIGIBLE" = "true" ]; then
  echo "✅ Test wallet IS eligible for Chapter 5 NFT!"
else
  echo "❌ Test wallet is NOT eligible"
  echo ""
  echo "Checking status..."
  flow scripts execute <<EOF
import SemesterZero from 0xb97ea2274b0ae5d2

access(all) fun main(userAddress: Address): AnyStruct {
  return SemesterZero.getChapter5Status(userAddress: userAddress)
}
EOF
  $TEST_WALLET --network=$NETWORK
  exit 1
fi

echo ""

# ========================================
# STEP 7: Airdrop NFT
# ========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 7: Airdrop Chapter 5 NFT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "🎁 Airdropping NFT..."
TX_ID=$(flow transactions send \
  ./cadence/transactions/airdrop-chapter5-nft.cdc \
  $TEST_WALLET \
  --network=$NETWORK \
  --signer=$ADMIN_ACCOUNT \
  --gas-limit=1000 \
  | grep "ID" | awk '{print $2}')

echo "✅ NFT Airdropped!"
echo "   Transaction: $TX_ID"
echo ""

# ========================================
# STEP 8: Verify NFT in Wallet
# ========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 8: Verify NFT in Wallet"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

NFT_IDS=$(flow scripts execute <<EOF
import SemesterZero from 0xb97ea2274b0ae5d2

access(all) fun main(userAddress: Address): [UInt64] {
  let collectionRef = getAccount(userAddress)
    .capabilities.get<&SemesterZero.Chapter5Collection>(SemesterZero.Chapter5CollectionPublicPath)
    .borrow()
    ?? panic("No collection found")
  
  return collectionRef.getIDs()
}
EOF
$TEST_WALLET --network=$NETWORK)

echo "NFT IDs in collection: $NFT_IDS"
echo ""

# Get NFT metadata
echo "📊 NFT Metadata:"
flow scripts execute <<EOF
import SemesterZero from 0xb97ea2274b0ae5d2
import MetadataViews from 0x631e88ae7f1d7c20

access(all) fun main(userAddress: Address, nftID: UInt64): {String: String} {
  let collectionRef = getAccount(userAddress)
    .capabilities.get<&SemesterZero.Chapter5Collection>(SemesterZero.Chapter5CollectionPublicPath)
    .borrow()!
  
  let nftRef = collectionRef.borrowChapter5NFT(id: nftID)!
  
  return nftRef.metadata
}
EOF
$TEST_WALLET 0 --network=$NETWORK

echo ""

# ========================================
# SUCCESS!
# ========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ TEST COMPLETE!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎉 Chapter 5 NFT airdrop system is working!"
echo ""
echo "Next steps:"
echo "1. Deploy updated contract to mainnet (if not already)"
echo "2. Test with real user wallets on mainnet"
echo "3. Upload unrevealed image to Google Storage"
echo "4. Launch on Oct 31!"
