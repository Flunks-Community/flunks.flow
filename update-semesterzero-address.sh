#!/bin/bash

# Update SemesterZero Address References
# Run this after deploying SemesterZero to your fresh mainnet account

NEW_ADDRESS=$1

if [ -z "$NEW_ADDRESS" ]; then
    echo "❌ Please provide the address where SemesterZero was deployed"
    echo "Usage: ./update-semesterzero-address.sh <address>"
    echo "Example: ./update-semesterzero-address.sh 0x1234567890abcdef"
    exit 1
fi

echo "🔄 Updating SemesterZero address references to: $NEW_ADDRESS"
echo ""

# Update flow.json
echo "Updating flow.json..."
sed -i '' "s/SERVICE_ACCOUNT_ADDRESS/$NEW_ADDRESS/g" flow.json

# Update setup-semesterzero-collection.cdc
echo "Updating setup-semesterzero-collection.cdc..."
sed -i '' "s/0xSEMESTERZERO_ADDRESS/$NEW_ADDRESS/g" setup-semesterzero-collection.cdc

# Update test-semesterzero-airdrop.sh
echo "Updating test-semesterzero-airdrop.sh..."
sed -i '' "s/0xSEMESTERZERO_ADDRESS/$NEW_ADDRESS/g" test-semesterzero-airdrop.sh

# Add alias to SemesterZero contract in flow.json
echo "Adding mainnet alias to SemesterZero contract..."
TEMP_FILE=$(mktemp)

# Use jq to add the alias if available, otherwise use sed
if command -v jq &> /dev/null; then
    jq ".contracts.SemesterZero.aliases.mainnet = \"$NEW_ADDRESS\"" flow.json > "$TEMP_FILE"
    mv "$TEMP_FILE" flow.json
else
    # Manual sed approach - add aliases section if it doesn't exist
    sed -i '' "s|\"SemesterZero\": \"cadence/contracts/SemesterZero_Hackathon.cdc\"|\"SemesterZero\": {\n\t\t\t\"source\": \"cadence/contracts/SemesterZero_Hackathon.cdc\",\n\t\t\t\"aliases\": {\n\t\t\t\t\"mainnet\": \"$NEW_ADDRESS\"\n\t\t\t}\n\t\t}|g" flow.json
fi

echo ""
echo "✅ All references updated!"
echo ""
echo "📋 Updated files:"
echo "  - flow.json"
echo "  - setup-semesterzero-collection.cdc"
echo "  - test-semesterzero-airdrop.sh"
echo ""
echo "🎯 SemesterZero is now configured for address: $NEW_ADDRESS"
echo ""
echo "Next steps:"
echo "1. Verify flow.json has the correct address"
echo "2. Test collection setup: flow transactions send setup-semesterzero-collection.cdc --network mainnet --signer <user>"
echo "3. Run airdrop test: ./test-semesterzero-airdrop.sh <recipient-address>"
