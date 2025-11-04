#!/bin/bash

echo "🎃 Updating Halloween GumDrop on MAINNET with multiple addresses..."
echo ""

# Step 1: Close the existing drop
echo "Step 1: Closing existing GumDrop..."
flow transactions send cadence/transactions/admin-close-gum-drop-mainnet.cdc \
  --network mainnet \
  --signer mainnet-account \
  --gas-limit 1000

echo ""
echo "Step 2: Creating new GumDrop with multiple eligible addresses..."

# Step 2: Create new drop with both addresses
flow transactions send cadence/transactions/admin-create-gum-drop-mainnet.cdc \
  --args-json '[
    {"type":"String","value":"halloween-2025"},
    {"type":"Array","value":[
      {"type":"Address","value":"0x807c3d470888cc48"},
      {"type":"Address","value":"0xbfffec679fff3a94"}
    ]},
    {"type":"UFix64","value":"100.0"},
    {"type":"UFix64","value":"259200.0"}
  ]' \
  --network mainnet \
  --signer mainnet-account \
  --gas-limit 1000

echo ""
echo "✅ Halloween GumDrop updated on mainnet!"
echo "Drop ID: halloween-2025"
echo "Amount: 100 GUM per claim"
echo "Duration: 72 hours"
echo "Eligible addresses:"
echo "  - 0x807c3d470888cc48 (mainnet-account)"
echo "  - 0xbfffec679fff3a94 (flunks-community)"
