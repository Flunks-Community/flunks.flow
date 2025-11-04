#!/bin/bash

# Flow Actions: Schedule Halloween GumDrop to start automatically
# This will trigger the startDrop() transaction at the specified time

echo "🎃 Setting up Flow Actions for Halloween GumDrop..."
echo ""
echo "Schedule Details:"
echo "  Trigger Time: October 31, 2025 at 12:01 AM EST (Unix: 1730347260)"
echo "  Action: Call FlunksGumDrop.startDrop()"
echo "  Drop Start: 1730347260.0 (Oct 31, 12:01 AM EST)"
echo "  Drop End: 1730606460.0 (Nov 3, 12:01 AM EST)"
echo "  GUM Amount: 100 per claim"
echo ""

# Note: Flow Actions might require using their dashboard or API
# Visit: https://developers.flow.com/blockchain-development-tutorials/forte/flow-actions

echo "⚠️  MANUAL SETUP REQUIRED:"
echo ""
echo "1. Visit the Flow Actions dashboard"
echo "2. Connect wallet: 0x807c3d470888cc48"
echo "3. Create new action:"
echo "   - Transaction: cadence/transactions/start-halloween-drop-mainnet.cdc"
echo "   - Network: mainnet"
echo "   - Trigger Time: 1730347260 (Oct 31, 2025 12:01 AM EST)"
echo "   - Arguments:"
echo "     * startTime: 1730347260.0"
echo "     * endTime: 1730606460.0"
echo "     * gumPerFlunk: 100"
echo ""
echo "4. Confirm and schedule the action"
echo ""
echo "Once scheduled, the drop will automatically activate at 12:01 AM on Halloween! 🎃"
