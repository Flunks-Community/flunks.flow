#!/bin/bash

# Create New Flow Mainnet Account for SemesterZero
# This uses your existing private key to create a funded mainnet account

echo "🔑 Creating Flow Mainnet Account for SemesterZero..."
echo ""
echo "Public Key: ca891ed0a4ab04a1ed935ae8e5a3fcca94d0d1a5633bccf1c17bc6905dbd6cc6cd15650bf83645101ad1ff9a6bbd61657fe6fbb5058789227c824d6e58581f68"
echo ""

# Step 1: Create account using an existing funded account
echo "📋 To create this account, you need to:"
echo ""
echo "Option 1: Use Flow Wallet (Recommended)"
echo "  1. Go to https://wallet.flow.com"
echo "  2. Create a new account or use existing"
echo "  3. The account will be automatically created and funded"
echo "  4. Import your private key if needed"
echo ""
echo "Option 2: Use existing mainnet account to create child account"
echo "  Run this command with a funded account:"
echo ""
echo "  flow accounts create \\"
echo "    --key ca891ed0a4ab04a1ed935ae8e5a3fcca94d0d1a5633bccf1c17bc6905dbd6cc6cd15650bf83645101ad1ff9a6bbd61657fe6fbb5058789227c824d6e58581f68 \\"
echo "    --sig-algo ECDSA_P256 \\"
echo "    --hash-algo SHA2_256 \\"
echo "    --network mainnet \\"
echo "    --signer mainnet-account"
echo ""
echo "Option 3: Fund via Faucet (if available)"
echo "  Check https://faucet.flow.com for mainnet funding options"
echo ""
echo "💡 Once created, run this to get the address:"
echo "   flow accounts get <ADDRESS> --network mainnet"
echo ""
