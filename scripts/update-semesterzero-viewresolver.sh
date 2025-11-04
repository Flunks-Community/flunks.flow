#!/bin/bash

# Update SemesterZero contract to add ViewResolver for Token List Registration
# This adds getContractViews() and resolveContractView() functions

echo "🚀 Updating SemesterZero contract with ViewResolver implementation..."
echo ""
echo "⚠️  IMPORTANT: This will UPDATE the contract on mainnet"
echo "Account: 0xce9dd43888d99574 (semester-zero-account)"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "❌ Cancelled"
    exit 1
fi

# Deploy the updated contract
flow accounts update-contract \
  cadence/contracts/SemesterZero_Hackathon.cdc \
  --signer semester-zero-account \
  --network mainnet

if [ $? -eq 0 ]; then
  echo ""
  echo "✅ Contract updated successfully!"
  echo ""
  echo "Next steps:"
  echo "1. Verify the contract with:"
  echo "   flow scripts execute cadence/scripts/check-token-list-validity.cdc 0xce9dd43888d99574 SemesterZero --network mainnet"
  echo ""
  echo "2. Register on token list with:"
  echo "   flow transactions send cadence/transactions/register-flunks-to-token-list.cdc 0xce9dd43888d99574 SemesterZero --signer semester-zero-account --network mainnet"
else
  echo ""
  echo "❌ Contract update failed"
  exit 1
fi
