#!/bin/bash

# FlunksGraduation Cadence 1.0 Update Script
# This creates a transaction to update the contract manually

echo "🔄 Creating contract update transaction..."

# Get contract code and convert to hex
CONTRACT_HEX=$(cat cadence/contracts/FlunksGraduation.cdc | xxd -p | tr -d '\n')

echo "📝 Contract code converted to hex"
echo "📏 Size: ${#CONTRACT_HEX} characters"

# Create transaction file
cat > /tmp/update-flunks-graduation.cdc << 'EOF'
transaction(name: String, code: String) {
    prepare(signer: auth(UpdateContract) &Account) {
        signer.contracts.update(name: name, code: code.decodeHex())
    }
}
EOF

echo "✅ Transaction file created"
echo ""
echo "Now run:"
echo "flow transactions send /tmp/update-flunks-graduation.cdc \\"
echo "  --arg String:\"FlunksGraduation\" \\"
echo "  --arg String:\"${CONTRACT_HEX}\" \\"
echo "  --network mainnet --signer mainnet-account"
