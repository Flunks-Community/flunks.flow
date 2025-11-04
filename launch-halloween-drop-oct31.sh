#!/bin/bash

# 🎃 Halloween GumDrop - Manual Launch for Oct 31, 2025
# Run this command at 12:01 AM EST on October 31, 2025

echo "🎃 Halloween GumDrop - Manual Launch"
echo "===================================="
echo ""
echo "⏰ IMPORTANT: Run this at exactly 12:01 AM EST on Oct 31, 2025"
echo ""

# Oct 31, 2025, 12:01 AM EST → Unix timestamp: 1730347260
# Nov 3, 2025, 12:01 AM EST → Unix timestamp: 1730606460
START_TIME="1730347260.0"
END_TIME="1730606460.0"
GUM_AMOUNT="100.0"

echo "📝 Starting Halloween GumDrop with:"
echo "   Start: Oct 31, 2025 at 12:01 AM EST"
echo "   End:   Nov 3, 2025 at 12:01 AM EST"
echo "   Reward: 100 GUM per Flunks NFT"
echo ""

flow transactions send \
  cadence/transactions/start-halloween-drop-mainnet.cdc \
  --network mainnet \
  --signer mainnet-account \
  --args-json "[
    {\"type\":\"UFix64\",\"value\":\"$START_TIME\"},
    {\"type\":\"UFix64\",\"value\":\"$END_TIME\"},
    {\"type\":\"UFix64\",\"value\":\"$GUM_AMOUNT\"}
  ]"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ SUCCESS! Halloween GumDrop is now ACTIVE!"
    echo ""
    echo "🎃 Users can claim 100 GUM per Flunks NFT"
    echo "⏰ Drop runs for 72 hours until Nov 3, 12:01 AM EST"
    echo ""
else
    echo ""
    echo "❌ Failed to start drop. Check your connection and try again."
    echo ""
fi
