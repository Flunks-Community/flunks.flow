#!/bin/bash

echo "🎃 Creating Halloween GumDrop on MAINNET..."
echo ""

# Create the drop with 72-hour window (259200 seconds)
flow transactions send cadence/transactions/admin-create-gum-drop-mainnet.cdc \
  '"halloween-2025"' \
  '100.0' \
  '259200.0' \
  '["0x807c3d470888cc48"]' \
  --network mainnet \
  --signer mainnet-account \
  --gas-limit 1000

echo ""
echo "✅ Halloween GumDrop created on mainnet!"
echo "Drop ID: halloween-2025"
echo "Amount: 100 GUM per claim"
echo "Duration: 72 hours"
echo "Eligible: 0x807c3d470888cc48 (mainnet account)"
