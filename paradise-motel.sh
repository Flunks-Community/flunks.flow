#!/bin/bash
# Paradise Motel Day/Night Helper Script
# Manages dynamic day/night images for Paradise Motel NFTs

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
NETWORK="${FLOW_NETWORK:-testnet}"

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════╗"
echo "║   🌅 PARADISE MOTEL DAY/NIGHT SYSTEM 🌙          ║"
echo "╚═══════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${YELLOW}What would you like to do?${NC}\n"
echo "1) Get current image for a user"
echo "2) Check time context for multiple users"
echo "3) Test timezone calculation"
echo "4) Deploy ParadiseMotel contract"
echo "5) View ParadiseMotel events"
echo "6) Exit"
echo ""
read -p "Enter choice [1-6]: " choice

case $choice in
  1)
    echo -e "\n${BLUE}=== Get Current Paradise Motel Image ===${NC}"
    read -p "Enter owner address: " owner
    read -p "Enter day image URI: " day_image
    read -p "Enter night image URI: " night_image
    
    echo -e "\n${YELLOW}Querying blockchain...${NC}\n"
    
    flow scripts execute cadence/scripts/paradise-motel-get-image.cdc \
      --arg Address:$owner \
      --arg String:"$day_image" \
      --arg String:"$night_image" \
      --network $NETWORK
    
    echo -e "\n${GREEN}✓ Query complete!${NC}"
    ;;
    
  2)
    echo -e "\n${BLUE}=== Batch Check Time Context ===${NC}"
    read -p "Enter addresses (comma-separated): " addresses_input
    
    # Convert comma-separated to array format
    IFS=',' read -ra ADDR <<< "$addresses_input"
    addresses_arg="["
    for i in "${!ADDR[@]}"; do
      addresses_arg+="${ADDR[$i]}"
      if [ $i -lt $((${#ADDR[@]} - 1)) ]; then
        addresses_arg+=","
      fi
    done
    addresses_arg+="]"
    
    echo -e "\n${YELLOW}Querying blockchain...${NC}\n"
    
    flow scripts execute cadence/scripts/paradise-motel-batch-time-context.cdc \
      --arg "Address:$addresses_arg" \
      --network $NETWORK
    
    echo -e "\n${GREEN}✓ Query complete!${NC}"
    ;;
    
  3)
    echo -e "\n${BLUE}=== Test Timezone Calculation ===${NC}"
    echo "Common timezones:"
    echo "  -8: PST (Los Angeles)"
    echo "  -5: EST (New York)"
    echo "   0: UTC (London)"
    echo "   1: CET (Paris)"
    echo "   9: JST (Tokyo)"
    echo ""
    read -p "Enter timezone offset: " timezone
    
    echo -e "\n${YELLOW}Checking timezone $timezone...${NC}\n"
    
    flow scripts execute cadence/scripts/paradise-motel-check-timezone.cdc \
      --arg Int:$timezone \
      --network $NETWORK
    
    echo -e "\n${GREEN}✓ Check complete!${NC}"
    ;;
    
  4)
    echo -e "\n${BLUE}=== Deploy ParadiseMotel Contract ===${NC}"
    echo -e "${YELLOW}Network: $NETWORK${NC}"
    read -p "Enter your account name (from flow.json): " account
    
    echo -e "\n${YELLOW}Deploying contract...${NC}\n"
    
    flow accounts add-contract ParadiseMotel \
      ./cadence/contracts/ParadiseMotel.cdc \
      --network $NETWORK \
      --signer $account
    
    echo -e "\n${GREEN}✓ Contract deployed!${NC}"
    ;;
    
  5)
    echo -e "\n${BLUE}=== View ParadiseMotel Events ===${NC}"
    read -p "Enter contract address: " contract_address
    read -p "Enter start block height: " start_block
    read -p "Enter end block height: " end_block
    
    echo -e "\n${YELLOW}Fetching events...${NC}\n"
    
    echo -e "${GREEN}ImageSwitched events:${NC}"
    flow events get A.$contract_address.ParadiseMotel.ImageSwitched \
      --start $start_block \
      --end $end_block \
      --network $NETWORK
    
    echo -e "\n${GREEN}DayNightCycleChecked events:${NC}"
    flow events get A.$contract_address.ParadiseMotel.DayNightCycleChecked \
      --start $start_block \
      --end $end_block \
      --network $NETWORK
    
    echo -e "\n${GREEN}✓ Events retrieved!${NC}"
    ;;
    
  6)
    echo -e "\n${GREEN}Goodbye! 🌅🌙${NC}\n"
    exit 0
    ;;
    
  *)
    echo -e "${RED}Invalid choice${NC}"
    exit 1
    ;;
esac

echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Paradise Motel System Ready            ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════╝${NC}"
echo ""
