#!/bin/bash

# Create Halloween GumDrop on Testnet
# Run this script to activate the 72-hour claim window

echo "🎃 Creating Halloween GumDrop on Testnet..."
echo ""

# Configuration
DROP_ID="halloween-2025"
AMOUNT="100.0"  # 100 GUM per claim
DURATION="259200.0"  # 72 hours in seconds (72 * 60 * 60)

# Eligible addresses (add your test wallet address here!)
# Replace with actual wallet addresses that should be able to claim
ELIGIBLE_ADDRESS1="0x50b39b4c0696c16a"  # ← YOUR WALLET ADDRESS

echo "Drop ID: $DROP_ID"
echo "Amount per claim: $AMOUNT GUM"
echo "Duration: 72 hours"
echo "Eligible address: $ELIGIBLE_ADDRESS1"
echo ""
echo "Sending transaction..."
echo ""

# Run the transaction
flow transactions send cadence/transactions/admin-create-gum-drop.cdc \
  "$DROP_ID" \
  "$AMOUNT" \
  "$DURATION" \
  "[$ELIGIBLE_ADDRESS1]" \
  --signer Flunks2.0 \
  --network testnet

echo ""
echo "✅ Done! Check the transaction result above."
echo ""
echo "Now go to your website and the pumpkin button should appear!"
