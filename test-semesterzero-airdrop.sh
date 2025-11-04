#!/bin/bash

# Test SemesterZero Airdrop System
# This tests the Chapter 5 NFT airdrop functionality

RECIPIENT_ADDRESS=$1

if [ -z "$RECIPIENT_ADDRESS" ]; then
    echo "Usage: ./test-semesterzero-airdrop.sh <recipient-address>"
    echo "Example: ./test-semesterzero-airdrop.sh 0x1234567890abcdef"
    exit 1
fi

echo "🎯 Testing SemesterZero Airdrop to: $RECIPIENT_ADDRESS"
echo ""

# First, make sure the recipient has a collection
echo "Step 1: Setting up collection for recipient..."
flow transactions send ./setup-semesterzero-collection.cdc \
    --network mainnet \
    --signer $RECIPIENT_ADDRESS

if [ $? -ne 0 ]; then
    echo "⚠️  Collection setup failed or already exists. Continuing..."
fi

echo ""
echo "Step 2: Creating test airdrop transaction..."

# Create the airdrop transaction
cat > .tmp/test-airdrop.cdc << 'EOF'
import SemesterZero from 0xce9dd43888d99574
import NonFungibleToken from 0x1d7e57aa55817448

transaction(recipientAddress: Address) {
    let adminRef: &SemesterZero.Admin
    
    prepare(signer: auth(BorrowValue) &Account) {
        self.adminRef = signer.storage.borrow<&SemesterZero.Admin>(
            from: SemesterZero.AdminStoragePath
        ) ?? panic("Could not borrow admin reference")
    }
    
    execute {
        // Mint Chapter 5 NFT
        self.adminRef.mintChapter5NFT(
            recipient: recipientAddress,
            metadata: {
                "name": "Test Chapter 5 NFT",
                "description": "Test airdrop for Semester Zero",
                "thumbnail": "https://flunks.io/images/chapter5-test.png"
            }
        )
        
        log("✅ Test NFT airdropped successfully!")
    }
}
EOF

echo ""
echo "Step 3: Sending airdrop transaction..."
flow transactions send .tmp/test-airdrop.cdc \
    --arg Address:$RECIPIENT_ADDRESS \
    --network mainnet \
    --signer fresh-mainnet-account

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Airdrop test completed successfully!"
    echo ""
    echo "📊 Verify the NFT:"
    echo "Check the recipient's collection at: $RECIPIENT_ADDRESS"
else
    echo ""
    echo "❌ Airdrop failed. Check the error above."
    exit 1
fi

# Cleanup
rm -f .tmp/test-airdrop.cdc
