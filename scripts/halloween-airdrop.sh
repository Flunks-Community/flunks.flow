#!/bin/bash

# Halloween Airdrop Script
# Quick helper to create and manage Halloween GUM drops

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "🎃👻 Halloween GUM Airdrop Tool 👻🎃"
echo ""

# Configuration
NETWORK="testnet"  # Change to "mainnet" for production
ADMIN_ADDRESS="0x..." # Set your admin address

# Function to get current Unix timestamp
get_timestamp() {
    date +%s
}

# Function to create a Halloween drop
create_drop() {
    echo -e "${YELLOW}Creating Halloween Drop...${NC}"
    
    # Halloween 2025 dates
    START_TIME=$(date -j -f "%Y-%m-%d %H:%M:%S" "2025-10-18 00:00:00" +%s)
    END_TIME=$(date -j -f "%Y-%m-%d %H:%M:%S" "2025-10-31 23:59:59" +%s)
    
    echo "Start: $(date -r $START_TIME)"
    echo "End: $(date -r $END_TIME)"
    
    flow transactions send ./cadence/transactions/halloween-create-drop.cdc \
        --arg String:"🎃 Halloween Treat 2025" \
        --arg String:"Spooky GUM treats for all Flunks holders! Claim your Halloween bonus before it disappears into the night! 👻" \
        --arg UFix64:100.0 \
        --arg UFix64:${START_TIME}.0 \
        --arg UFix64:${END_TIME}.0 \
        --arg Bool:true \
        --arg Int:1 \
        --arg UInt64:1000 \
        --network $NETWORK \
        --signer admin-account
    
    echo -e "${GREEN}✓ Halloween drop created!${NC}"
}

# Function to check active drops
check_drops() {
    echo -e "${YELLOW}Checking active drops...${NC}"
    
    flow scripts execute ./cadence/scripts/check-halloween-drop.cdc \
        --network $NETWORK
}

# Function to check user eligibility
check_eligibility() {
    if [ -z "$1" ]; then
        echo -e "${RED}Error: Please provide user address${NC}"
        echo "Usage: $0 check-user <address> <dropID>"
        exit 1
    fi
    
    USER_ADDRESS=$1
    DROP_ID=${2:-1}
    
    echo -e "${YELLOW}Checking eligibility for $USER_ADDRESS...${NC}"
    
    flow scripts execute ./cadence/scripts/check-user-drop-eligibility.cdc \
        --arg Address:$USER_ADDRESS \
        --arg UInt64:$DROP_ID \
        --network $NETWORK
}

# Function to do batch airdrop
batch_airdrop() {
    echo -e "${YELLOW}Starting batch airdrop...${NC}"
    
    # Example with multiple addresses
    # You can read from a CSV or JSON file
    
    # EXAMPLE - Replace with your actual addresses
    RECIPIENTS=(
        "0x1234567890123456"
        "0x2345678901234567"
        "0x3456789012345678"
    )
    
    AMOUNTS=(
        "100.0"
        "150.0"
        "200.0"
    )
    
    # Build argument strings
    RECIPIENT_ARGS=""
    for addr in "${RECIPIENTS[@]}"; do
        RECIPIENT_ARGS="$RECIPIENT_ARGS --arg Address:$addr"
    done
    
    AMOUNT_ARGS=""
    for amt in "${AMOUNTS[@]}"; do
        AMOUNT_ARGS="$AMOUNT_ARGS --arg UFix64:$amt"
    done
    
    flow transactions send ./cadence/transactions/halloween-batch-airdrop.cdc \
        $RECIPIENT_ARGS \
        $AMOUNT_ARGS \
        --network $NETWORK \
        --signer admin-account
    
    echo -e "${GREEN}✓ Batch airdrop complete!${NC}"
}

# Main menu
case "${1:-}" in
    create)
        create_drop
        ;;
    check)
        check_drops
        ;;
    check-user)
        check_eligibility $2 $3
        ;;
    batch)
        batch_airdrop
        ;;
    *)
        echo "Usage: $0 {create|check|check-user|batch}"
        echo ""
        echo "Commands:"
        echo "  create         - Create a new Halloween drop"
        echo "  check          - Check all active drops"
        echo "  check-user     - Check if user is eligible (requires address and dropID)"
        echo "  batch          - Run batch airdrop to predefined addresses"
        echo ""
        echo "Examples:"
        echo "  $0 create"
        echo "  $0 check"
        echo "  $0 check-user 0x1234... 1"
        echo "  $0 batch"
        exit 1
        ;;
esac
