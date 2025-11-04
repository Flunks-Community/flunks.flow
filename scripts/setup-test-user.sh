#!/bin/bash

# Setup Test User for Chapter 5 NFT Airdrop
# This script sets up wallet 0xbfffec679fff3a94 with:
# 1. UserProfile with timezone
# 2. Chapter5Collection
# 3. Marks as slacker complete
# 4. Marks as overachiever complete

WALLET="0xbfffec679fff3a94"
USER_ACCOUNT="flunks-community"  # The account we're setting up
ADMIN_ACCOUNT="semester-zero-account"  # Admin account for marking completion

echo "🚀 Setting up test user: $WALLET"
echo ""

# Step 1: Claim GumDrop (sets up profile + collection)
# Using EST timezone (UTC-5)
echo "📦 Step 1: Setting up UserProfile + Chapter5Collection..."
flow transactions send cadence/transactions/claim-gumdrop-with-timezone.cdc \
  --args-json '[{"type":"String","value":"TestUser"},{"type":"Int","value":"-5"}]' \
  --signer $USER_ACCOUNT \
  --network mainnet \
  --gas-limit 9999

if [ $? -eq 0 ]; then
  echo "✅ Profile and collection setup complete!"
else
  echo "❌ Failed to setup profile/collection"
  exit 1
fi

echo ""

# Step 2: Register as slacker complete (admin transaction)
echo "📝 Step 2: Marking as slacker complete..."
flow transactions send cadence/transactions/register-slacker-completion.cdc \
  $WALLET \
  --signer $ADMIN_ACCOUNT \
  --network mainnet \
  --gas-limit 9999

if [ $? -eq 0 ]; then
  echo "✅ Slacker completion registered!"
else
  echo "❌ Failed to register slacker completion"
  exit 1
fi

echo ""

# Step 3: Register as overachiever complete (admin transaction)
echo "🏆 Step 3: Marking as overachiever complete..."
flow transactions send cadence/transactions/register-overachiever-completion.cdc \
  $WALLET \
  --signer $ADMIN_ACCOUNT \
  --network mainnet \
  --gas-limit 9999

if [ $? -eq 0 ]; then
  echo "✅ Overachiever completion registered!"
else
  echo "❌ Failed to register overachiever completion"
  exit 1
fi

echo ""
echo "🎉 Setup complete! User is now eligible for NFT airdrop."
echo ""
echo "Verify status with:"
echo "flow scripts execute check-user-status.cdc $WALLET --network mainnet"
