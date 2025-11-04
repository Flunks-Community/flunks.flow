#!/bin/bash
# Paradise Motel Image Verification Script
# Tests your production Google Cloud Storage images

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Your production image URLs
DAY_IMAGE="https://storage.googleapis.com/flunks_public/images/paradise-motel-day.png"
NIGHT_IMAGE="https://storage.googleapis.com/flunks_public/images/paradise-motel-night.png"

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════╗"
echo "║   🌅 PARADISE MOTEL IMAGE VERIFICATION 🌙        ║"
echo "╚═══════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${YELLOW}Testing your production image URLs...${NC}\n"

# Test 1: Check day image accessibility
echo -e "${BLUE}Test 1: Day Image Accessibility${NC}"
echo "URL: $DAY_IMAGE"

if curl -s -I "$DAY_IMAGE" | grep -q "200 OK\|200"; then
    echo -e "${GREEN}✓ Day image is accessible!${NC}\n"
else
    echo -e "${RED}✗ Day image is NOT accessible!${NC}\n"
    exit 1
fi

# Test 2: Check night image accessibility
echo -e "${BLUE}Test 2: Night Image Accessibility${NC}"
echo "URL: $NIGHT_IMAGE"

if curl -s -I "$NIGHT_IMAGE" | grep -q "200 OK\|200"; then
    echo -e "${GREEN}✓ Night image is accessible!${NC}\n"
else
    echo -e "${RED}✗ Night image is NOT accessible!${NC}\n"
    exit 1
fi

# Test 3: Check image headers
echo -e "${BLUE}Test 3: Image Headers${NC}"
echo "Day Image Content-Type:"
curl -s -I "$DAY_IMAGE" | grep -i "content-type"

echo "Night Image Content-Type:"
curl -s -I "$NIGHT_IMAGE" | grep -i "content-type"
echo ""

# Test 4: Check image sizes
echo -e "${BLUE}Test 4: Image Sizes${NC}"

DAY_SIZE=$(curl -s -I "$DAY_IMAGE" | grep -i "content-length" | awk '{print $2}' | tr -d '\r')
NIGHT_SIZE=$(curl -s -I "$NIGHT_IMAGE" | grep -i "content-length" | awk '{print $2}' | tr -d '\r')

if [ -n "$DAY_SIZE" ]; then
    DAY_SIZE_KB=$((DAY_SIZE / 1024))
    echo -e "Day image size: ${GREEN}${DAY_SIZE_KB} KB${NC}"
else
    echo -e "Day image size: ${YELLOW}Unknown${NC}"
fi

if [ -n "$NIGHT_SIZE" ]; then
    NIGHT_SIZE_KB=$((NIGHT_SIZE / 1024))
    echo -e "Night image size: ${GREEN}${NIGHT_SIZE_KB} KB${NC}\n"
else
    echo -e "Night image size: ${YELLOW}Unknown${NC}\n"
fi

# Test 5: Download and verify (optional)
echo -e "${BLUE}Test 5: Download Test (Optional)${NC}"
read -p "Download images to verify locally? (y/n): " download_choice

if [ "$download_choice" = "y" ]; then
    echo -e "\n${YELLOW}Downloading images...${NC}\n"
    
    mkdir -p /tmp/paradise-motel-test
    
    if curl -s "$DAY_IMAGE" -o /tmp/paradise-motel-test/day.png; then
        echo -e "${GREEN}✓ Day image downloaded${NC}"
        ls -lh /tmp/paradise-motel-test/day.png
    else
        echo -e "${RED}✗ Failed to download day image${NC}"
    fi
    
    if curl -s "$NIGHT_IMAGE" -o /tmp/paradise-motel-test/night.png; then
        echo -e "${GREEN}✓ Night image downloaded${NC}"
        ls -lh /tmp/paradise-motel-test/night.png
    else
        echo -e "${RED}✗ Failed to download night image${NC}"
    fi
    
    echo -e "\n${YELLOW}Images saved to: /tmp/paradise-motel-test/${NC}"
    echo -e "${YELLOW}Opening images...${NC}\n"
    
    open /tmp/paradise-motel-test/day.png 2>/dev/null || echo "View day image at: /tmp/paradise-motel-test/day.png"
    open /tmp/paradise-motel-test/night.png 2>/dev/null || echo "View night image at: /tmp/paradise-motel-test/night.png"
fi

# Test 6: Test with testnet (if deployed)
echo -e "\n${BLUE}Test 6: Testnet Integration Test${NC}"
read -p "Is ParadiseMotel.cdc deployed to testnet? (y/n): " deployed

if [ "$deployed" = "y" ]; then
    read -p "Enter your testnet address: " testnet_address
    
    if [ -n "$testnet_address" ]; then
        echo -e "\n${YELLOW}Testing with testnet...${NC}\n"
        
        flow scripts execute cadence/scripts/paradise-motel-get-image.cdc \
          --arg Address:$testnet_address \
          --arg String:"$DAY_IMAGE" \
          --arg String:"$NIGHT_IMAGE" \
          --network testnet
        
        echo -e "\n${GREEN}✓ Testnet test complete!${NC}"
    fi
else
    echo -e "${YELLOW}Skipping testnet test. Deploy ParadiseMotel.cdc first.${NC}"
fi

# Summary
echo -e "\n${BLUE}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              VERIFICATION COMPLETE                ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════╝${NC}\n"

echo -e "${GREEN}✓ All image URLs are working!${NC}"
echo -e "\nYour Paradise Motel images are ready to use:\n"
echo -e "Day:   ${BLUE}$DAY_IMAGE${NC}"
echo -e "Night: ${BLUE}$NIGHT_IMAGE${NC}\n"

echo -e "${YELLOW}Next steps:${NC}"
echo "1. Deploy ParadiseMotel.cdc to testnet"
echo "2. Test with ./paradise-motel.sh"
echo "3. Set up Supabase table with these URLs"
echo "4. Integrate with your website API"
echo ""
