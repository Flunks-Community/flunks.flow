#!/bin/bash

# Deploy SemesterZero to Fresh Mainnet Account
# This bypasses the token list issue with the original Flunks contract address

echo "🚀 Deploying SemesterZero to Fresh Mainnet Account..."
echo ""
echo "⚠️  IMPORTANT: Update flow.json with your fresh-mainnet-account address first!"
echo ""
echo "Step 1: Get your fresh account address"
echo "Run: cat fresh-mainnet-account.pkey"
echo ""
echo "Step 2: Update flow.json"
echo "Replace 'SERVICE_ACCOUNT_ADDRESS' with your actual address"
echo ""
echo "Step 3: Deploy the contract"
echo "Running: flow accounts add-contract SemesterZero ./cadence/contracts/SemesterZero_Hackathon.cdc --network mainnet --signer fresh-mainnet-account"
echo ""

read -p "Have you updated the address in flow.json? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "❌ Please update flow.json first, then run this script again"
    exit 1
fi

echo ""
echo "🔄 Deploying SemesterZero contract..."
flow accounts add-contract SemesterZero ./cadence/contracts/SemesterZero_Hackathon.cdc \
    --network mainnet \
    --signer fresh-mainnet-account

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ SemesterZero contract deployed successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Update your frontend config to use the new SemesterZero address"
    echo "2. Set up collections for users"
    echo "3. Begin airdrop testing"
    echo ""
    echo "🎯 Your SemesterZero contract is now at: [YOUR_FRESH_ACCOUNT_ADDRESS]"
else
    echo ""
    echo "❌ Deployment failed. Check the error above."
    exit 1
fi
