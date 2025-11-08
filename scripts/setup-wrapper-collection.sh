#!/bin/bash

# Setup FlunksSemesterZero collection on the deployer account
# This creates the public paths that Fixes.World needs to detect

echo "Setting up FlunksSemesterZero collection..."

flow transactions send cadence/transactions/setup-wrapper-collection.cdc \
  --network=mainnet \
  --signer=semester-zero-account

echo ""
echo "✅ Collection setup complete!"
echo ""
echo "Now the Fixes.World site should be able to detect your contract properly."
echo "Try registering again at: https://token-list.fixes.world"
