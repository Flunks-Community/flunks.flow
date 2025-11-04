#!/bin/bash

# Run this from ~/Desktop/flunks.flow directory
# Updates FlunksGraduation contract to Cadence 1.0

echo "🚀 Updating FlunksGraduation to Cadence 1.0..."
echo ""
echo "Contract: ./cadence/contracts/FlunksGraduation.cdc"
echo "Network: mainnet"
echo "Account: 0x807c3d470888cc48"
echo ""

flow accounts update-contract FlunksGraduation \
  ./cadence/contracts/FlunksGraduation.cdc \
  --network mainnet \
  --signer mainnet-account

if [ $? -eq 0 ]; then
  echo ""
  echo "✅ SUCCESS! FlunksGraduation updated to Cadence 1.0"
  echo ""
  echo "📝 Next: Try registering SemesterZero on Token List again"
else
  echo ""
  echo "❌ Update failed. Check error above."
fi
