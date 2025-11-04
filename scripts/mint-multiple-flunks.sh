#!/bin/bash

# Mint multiple Flunks NFTs with different images from Google Cloud Storage
# Usage: ./mint-multiple-flunks.sh

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting bulk Flunks NFT minting...${NC}"

# Array of NFT data (name, description, image_filename)
declare -a nfts=(
    "Flunks Community #1|A unique Flunk from the original collection|000695c5e8344e2c662dd7e8641a8991eb00d3bc09110482cfea9d5a0c1510f3.jpg"
    "Flunks Community #2|Another distinguished member of the Flunks family|0011a9c21530d0a60a9dca18601fefe55f54a6db2d66b0eb371376b243db0b07.jpg"
    "Flunks Community #3|A special Flunk with unique characteristics|0013fbd33380d2ea4a2a2e1ebd01ae143cf1400051e2d087c5c32cebdd49a72f.jpg"
)

# Base URL for images
BASE_IMAGE_URL="https://storage.googleapis.com/flunks_public/flunks/"

# Recipient address (your flunks community account)
RECIPIENT="0xbfffec679fff3a94"

# Counter for minting
counter=1

# Loop through each NFT and mint
for nft_data in "${nfts[@]}"; do
    # Parse the NFT data
    IFS='|' read -r name description image_file <<< "$nft_data"
    
    # Construct full image URL
    image_url="${BASE_IMAGE_URL}${image_file}"
    
    echo -e "${BLUE}Minting NFT ${counter}: ${name}${NC}"
    echo "Description: ${description}"
    echo "Image: ${image_url}"
    echo ""
    
    # Execute the minting transaction
    flow transactions send ./cadence/transactions/mint-mainnet-flunks-v2.cdc \
        "$RECIPIENT" \
        "$name" \
        "$description" \
        "$image_url" \
        --network mainnet \
        --signer flunks-community
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Successfully minted ${name}${NC}"
    else
        echo -e "${RED}❌ Failed to mint ${name}${NC}"
    fi
    
    echo "----------------------------------------"
    
    # Increment counter
    ((counter++))
    
    # Add a small delay between mints to avoid network issues
    sleep 2
done

echo -e "${GREEN}🎉 Bulk minting completed!${NC}"
echo ""
echo "Check your collection at:"
echo "https://www.flowview.app/account/${RECIPIENT}"
