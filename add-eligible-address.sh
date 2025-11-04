#!/bin/bash

# Add a new eligible address to the Halloween GumDrop
# Usage: ./add-eligible-address.sh 0xYOUR_ADDRESS_HERE

if [ -z "$1" ]; then
  echo "❌ Error: Please provide an address"
  echo "Usage: ./add-eligible-address.sh 0xYOUR_ADDRESS_HERE"
  exit 1
fi

NEW_ADDRESS="$1"

echo "🎃 Adding new eligible address to Halloween GumDrop..."
echo "Address: $NEW_ADDRESS"
echo ""

# First, close the old drop
echo "Step 1: Closing old drop..."
flow transactions send cadence/transactions/admin-close-gum-drop.cdc \
  --signer Flunks2.0 \
  --network testnet

echo ""
echo "Step 2: Creating new drop with updated address list..."
echo ""

# Create new drop with both addresses
DROP_ID="halloween-2025"
AMOUNT="100.0"
DURATION="259200.0"  # 72 hours

flow transactions send cadence/transactions/admin-create-gum-drop.cdc \
  "$DROP_ID" \
  "$AMOUNT" \
  "$DURATION" \
  "[$NEW_ADDRESS]" \
  --signer Flunks2.0 \
  --network testnet

echo ""
echo "✅ Done! Address $NEW_ADDRESS is now eligible."
echo "Refresh your website and try again!"
