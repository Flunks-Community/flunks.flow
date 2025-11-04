#!/bin/bash
# =====================================================
# QUICK TEST: Chapter 5 NFT Flow (Mainnet)
# =====================================================
# Tests the full Chapter 5 completion → NFT airdrop
# =====================================================

set -e

echo "🧪 Testing Chapter 5 NFT System on Mainnet"
echo "=========================================="
echo ""

# Your test wallet address
TEST_WALLET="0xe327216d843357f1"  # Your test wallet
ADMIN_SIGNER="mainnet-account"

echo "Test Wallet: $TEST_WALLET"
echo ""

# ========================================
# STEP 1: Check if SemesterZero is deployed
# ========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 1: Verify SemesterZero Contract"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create temp script
cat > /tmp/check-contract.cdc <<'EOF'
import SemesterZero from 0x807c3d470888cc48

access(all) fun main(): {String: UInt64} {
  return SemesterZero.getStats()
}
EOF

CONTRACT_CHECK=$(flow scripts execute /tmp/check-contract.cdc --network=mainnet)

if [[ $CONTRACT_CHECK == *"error"* ]]; then
  echo "❌ SemesterZero contract not found or error"
  echo "$CONTRACT_CHECK"
  exit 1
else
  echo "✅ SemesterZero contract is live!"
  echo "$CONTRACT_CHECK"
fi

echo ""

# ========================================
# STEP 2: Setup Chapter 5 Collection
# ========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 2: Setup Chapter 5 Collection"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cat > /tmp/check-collection.cdc <<'EOF'
import SemesterZero from 0x807c3d470888cc48

access(all) fun main(userAddress: Address): Bool {
  return getAccount(userAddress)
    .capabilities.get<&SemesterZero.Chapter5Collection>(SemesterZero.Chapter5CollectionPublicPath)
    .check()
}
EOF

HAS_COLLECTION=$(flow scripts execute /tmp/check-collection.cdc $TEST_WALLET --network=mainnet)

# Extract just the result value
HAS_COLLECTION_VALUE=$(echo "$HAS_COLLECTION" | grep -o "Result:.*" | sed 's/Result: //')

if [[ "$HAS_COLLECTION_VALUE" == "true" ]]; then
  echo "✅ Chapter 5 collection already exists"
else
  echo "📦 Setting up Chapter 5 collection..."
  
  flow transactions send ./cadence/transactions/setup-chapter5-collection.cdc \
    --network=mainnet \
    --signer=$ADMIN_SIGNER \
    --gas-limit=1000
    
  echo "✅ Collection created!"
fi

echo ""

# ========================================
# STEP 3: Register Slacker Completion
# ========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 3: Register Slacker Objective"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "📝 Calling registerSlackerCompletion()..."
flow transactions send \
  ./cadence/transactions/register-slacker-completion.cdc \
  $TEST_WALLET \
  --network=mainnet \
  --signer=$ADMIN_SIGNER \
  --gas-limit=1000

echo "✅ Slacker objective registered!"
echo ""

# ========================================
# STEP 4: Register Overachiever Completion
# ========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 4: Register Overachiever Objective"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "📝 Calling registerOverachieverCompletion()..."
flow transactions send \
  ./cadence/transactions/register-overachiever-completion.cdc \
  $TEST_WALLET \
  --network=mainnet \
  --signer=$ADMIN_SIGNER \
  --gas-limit=1000

echo "✅ Overachiever objective registered!"
echo ""

# ========================================
# STEP 5: Check Eligibility
# ========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 5: Check NFT Eligibility"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cat > /tmp/check-eligibility.cdc <<'EOF'
import SemesterZero from 0x807c3d470888cc48

access(all) fun main(userAddress: Address): Bool {
  return SemesterZero.isEligibleForChapter5NFT(userAddress: userAddress)
}
EOF

ELIGIBLE=$(flow scripts execute /tmp/check-eligibility.cdc $TEST_WALLET --network=mainnet)

echo "Eligible for NFT: $ELIGIBLE"

# Extract just the result value (after "Result: ")
ELIGIBLE_VALUE=$(echo "$ELIGIBLE" | grep -o "Result:.*" | sed 's/Result: //')

if [[ "$ELIGIBLE_VALUE" == "true" ]]; then
  echo "✅ Ready for airdrop!"
else
  echo "❌ Not eligible yet"
  
  # Show status
  echo ""
  echo "Chapter 5 Status:"
  cat > /tmp/get-status.cdc <<'EOF'
import SemesterZero from 0x807c3d470888cc48

access(all) fun main(userAddress: Address): AnyStruct {
  return SemesterZero.getChapter5Status(userAddress: userAddress)
}
EOF
  flow scripts execute /tmp/get-status.cdc $TEST_WALLET --network=mainnet
  
  exit 1
fi

echo ""

# ========================================
# STEP 6: Airdrop NFT
# ========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 6: Airdrop Paradise Motel NFT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "🎁 Airdropping NFT..."
TX_OUTPUT=$(flow transactions send \
  ./cadence/transactions/airdrop-chapter5-nft.cdc \
  $TEST_WALLET \
  --network=mainnet \
  --signer=$ADMIN_SIGNER \
  --gas-limit=1000 2>&1)

if [[ $TX_OUTPUT == *"error"* ]] || [[ $TX_OUTPUT == *"panic"* ]]; then
  echo "❌ Airdrop failed!"
  echo "$TX_OUTPUT"
  exit 1
else
  TX_ID=$(echo "$TX_OUTPUT" | grep "ID" | awk '{print $2}')
  echo "✅ NFT Airdropped!"
  echo "   Transaction: $TX_ID"
fi

echo ""

# ========================================
# STEP 7: Verify NFT
# ========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 7: Verify NFT in Collection"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cat > /tmp/get-nft-ids.cdc <<'EOF'
import SemesterZero from 0x807c3d470888cc48

access(all) fun main(userAddress: Address): [UInt64] {
  let collectionRef = getAccount(userAddress)
    .capabilities.get<&SemesterZero.Chapter5Collection>(SemesterZero.Chapter5CollectionPublicPath)
    .borrow()
    ?? panic("No collection found")
  
  return collectionRef.getIDs()
}
EOF

NFT_IDS=$(flow scripts execute /tmp/get-nft-ids.cdc $TEST_WALLET --network=mainnet)

echo "✅ NFT IDs in collection: $NFT_IDS"
echo ""

# Get NFT metadata
echo "📊 NFT Metadata:"
cat > /tmp/get-nft-metadata.cdc <<'EOF'
import SemesterZero from 0x807c3d470888cc48

access(all) fun main(userAddress: Address): {String: String} {
  let collectionRef = getAccount(userAddress)
    .capabilities.get<&SemesterZero.Chapter5Collection>(SemesterZero.Chapter5CollectionPublicPath)
    .borrow()!
  
  let nftIDs = collectionRef.getIDs()
  if nftIDs.length == 0 {
    panic("No NFTs found")
  }
  
  let nftRef = collectionRef.borrowChapter5NFT(id: nftIDs[0])!
  
  return nftRef.metadata
}
EOF
flow scripts execute /tmp/get-nft-metadata.cdc $TEST_WALLET --network=mainnet

echo ""

# ========================================
# SUCCESS!
# ========================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ FULL FLOW TEST COMPLETE!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎉 Paradise Motel NFT successfully airdropped!"
echo ""
echo "Check your wallet:"
echo "- Blocto: https://port.blocto.app/"
echo "- Flowdiver: https://flowdiver.io/account/$TEST_WALLET"
echo ""
echo "Next: Upload image to https://storage.googleapis.com/flunks_public/images/1.png"
