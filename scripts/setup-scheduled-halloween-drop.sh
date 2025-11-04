#!/bin/bash

# 🎃 Halloween GumDrop - Automated Scheduling Setup
# This script sets up scheduled transactions so the drop activates automatically on Oct 31, 2025

echo "🎃 Halloween GumDrop Automated Scheduling Setup"
echo "================================================"
echo ""

# Step 1: Deploy the HalloweenDropHandler contract
echo "📝 Step 1: Deploying HalloweenDropHandler contract to mainnet..."
echo ""
flow accounts add-contract HalloweenDropHandler \
  cadence/contracts/HalloweenDropHandler.cdc \
  --network mainnet \
  --signer mainnet-account

if [ $? -ne 0 ]; then
    echo "❌ Failed to deploy contract. Check if it's already deployed."
    echo "   To update: flow accounts update-contract HalloweenDropHandler ./cadence/contracts/HalloweenDropHandler.cdc --network mainnet --signer mainnet-account"
    exit 1
fi

echo ""
echo "✅ Contract deployed!"
echo ""

# Step 2: Initialize the handler
echo "📝 Step 2: Initializing the Halloween Drop Handler..."
echo ""
flow transactions send cadence/transactions/init-halloween-handler.cdc \
  --network mainnet \
  --signer mainnet-account

if [ $? -ne 0 ]; then
    echo "❌ Failed to initialize handler"
    exit 1
fi

echo ""
echo "✅ Handler initialized!"
echo ""

# Step 3: Calculate time until Oct 31, 2025, 12:01 AM EST
echo "📝 Step 3: Calculating delay until Oct 31, 2025, 12:01 AM EST..."
echo ""

# Target time: Oct 31, 2025, 12:01 AM EST (Unix timestamp: 1730347260)
TARGET_TIME=1730347260

# Get current time
NOW=$(date +%s)

# Calculate delay in seconds
DELAY=$((TARGET_TIME - NOW))

echo "Current time: $(date)"
echo "Target time:  Oct 31, 2025, 12:01 AM EST"
echo "Delay:        $DELAY seconds ($((DELAY / 86400)) days, $(((DELAY % 86400) / 3600)) hours)"
echo ""

if [ $DELAY -lt 0 ]; then
    echo "⚠️  WARNING: Target time has already passed!"
    echo "   Using 60 second delay for testing..."
    DELAY=60
fi

# Step 4: Schedule the transaction
echo "📝 Step 4: Scheduling the Halloween GumDrop activation..."
echo ""
echo "Parameters:"
echo "  - Delay: $DELAY seconds"
echo "  - Priority: 0 (High)"
echo "  - Execution Effort: 1000"
echo ""

flow transactions send cadence/transactions/schedule-halloween-drop.cdc \
  --network mainnet \
  --signer mainnet-account \
  --args-json "[
    {\"type\":\"UFix64\",\"value\":\"$DELAY.0\"},
    {\"type\":\"UInt8\",\"value\":\"0\"},
    {\"type\":\"UInt64\",\"value\":\"1000\"}
  ]"

if [ $? -ne 0 ]; then
    echo "❌ Failed to schedule transaction"
    exit 1
fi

echo ""
echo "✅ SUCCESS!"
echo ""
echo "🎃 Halloween GumDrop will automatically activate on:"
echo "   Oct 31, 2025 at 12:01 AM EST"
echo ""
echo "📊 The drop will run for 72 hours until:"
echo "   Nov 3, 2025 at 12:01 AM EST"
echo ""
echo "💰 Reward: 100 GUM per Flunks NFT owned"
echo ""
echo "🔍 No further action needed - the blockchain will handle it!"
echo ""
