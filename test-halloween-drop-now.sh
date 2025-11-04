#!/bin/bash

echo "🎃 TESTING: Activating Halloween GumDrop NOW for testing..."
echo ""
echo "This will start the drop immediately so you can test the button."
echo "We'll end it after testing and then schedule it properly for Halloween."
echo ""

# Calculate timestamps for a 1-hour test window
NOW=$(date +%s)
START_TIME="${NOW}.0"
END_TIME="$((NOW + 3600)).0"  # 1 hour from now

echo "Test Window:"
echo "  Start: $(date -r $NOW)"
echo "  End: $(date -r $((NOW + 3600)))"
echo ""

flow transactions send cadence/transactions/start-halloween-drop-mainnet.cdc \
  "$START_TIME" \
  "$END_TIME" \
  100 \
  --network mainnet \
  --signer mainnet-account \
  --gas-limit 1000

echo ""
echo "✅ Test drop activated! Go to http://localhost:3000 to test the button!"
echo ""
echo "When done testing, run: ./end-halloween-drop.sh"
