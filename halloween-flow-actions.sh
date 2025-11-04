#!/bin/bash

# Halloween Flow Actions Autopush Helper
# Automated GUM airdrop using Forte's Flow Actions

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "🎃 Halloween Flow Actions Autopush 🎃"
echo ""

NETWORK="testnet"

# Test single user autopush
test_single_user() {
    echo -e "${YELLOW}Testing single user autopush...${NC}"
    
    USER_ADDRESS=${1:-"0x1234567890123456"}
    SUPABASE_BALANCE=${2:-"50.0"}
    HALLOWEEN_BONUS=${3:-"100.0"}
    
    echo "User: $USER_ADDRESS"
    echo "Supabase Balance: $SUPABASE_BALANCE GUM"
    echo "Halloween Bonus: $HALLOWEEN_BONUS GUM"
    echo "Total: $((SUPABASE_BALANCE + HALLOWEEN_BONUS)) GUM"
    echo ""
    
    flow transactions send cadence/transactions/halloween-autopush-user.cdc \
        --arg Address:$USER_ADDRESS \
        --arg UFix64:$SUPABASE_BALANCE \
        --arg UFix64:$HALLOWEEN_BONUS \
        --network $NETWORK \
        --signer admin-account
    
    echo -e "${GREEN}✓ Autopush complete!${NC}"
}

# Check Flow Actions events
check_events() {
    echo -e "${YELLOW}Checking Flow Actions events...${NC}"
    
    flow events get A.CONTRACT.DeFiActions.SourceWithdrawn \
        --last 20 \
        --network $NETWORK
    
    flow events get A.CONTRACT.DeFiActions.SinkDeposited \
        --last 20 \
        --network $NETWORK
}

# Verify user received GUM
verify_user() {
    if [ -z "$1" ]; then
        echo -e "${RED}Error: Please provide user address${NC}"
        exit 1
    fi
    
    USER_ADDRESS=$1
    
    echo -e "${YELLOW}Checking GUM balance for $USER_ADDRESS...${NC}"
    
    flow scripts execute cadence/scripts/get-gum-balance.cdc \
        --arg Address:$USER_ADDRESS \
        --network $NETWORK
}

# Estimate cost for batch autopush
estimate_cost() {
    USER_COUNT=${1:-1000}
    GAS_PRICE=0.0001  # ~0.0001 FLOW per transaction (Flow is CHEAP!)
    FLOW_USD=0.70     # ~$0.70 per FLOW
    
    TOTAL_FLOW=$(echo "$USER_COUNT * $GAS_PRICE" | bc)
    TOTAL_USD=$(echo "$TOTAL_FLOW * $FLOW_USD" | bc)
    
    echo -e "${YELLOW}Cost Estimation${NC}"
    echo "Users: $USER_COUNT"
    echo "Gas per TX: $GAS_PRICE FLOW (~$0.00007 USD)"
    echo "Total Gas: ~$TOTAL_FLOW FLOW"
    echo "Total Cost: ~\$$TOTAL_USD USD"
    echo ""
    echo "💰 Flow is incredibly cheap! Even 10,000 users costs <\$1"
    echo "Note: Actual cost may vary slightly based on transaction complexity"
}

# Deploy Flow Actions integration
deploy_actions() {
    echo -e "${YELLOW}Deploying SemesterZero with Flow Actions...${NC}"
    
    # This would update your contract with Flow Actions interfaces
    flow accounts update-contract SemesterZero \
        ./cadence/contracts/SemesterZero.cdc \
        --network $NETWORK \
        --signer admin-account
    
    echo -e "${GREEN}✓ Contract updated!${NC}"
}

# Main menu
case "${1:-}" in
    test)
        test_single_user $2 $3 $4
        ;;
    events)
        check_events
        ;;
    verify)
        verify_user $2
        ;;
    estimate)
        estimate_cost $2
        ;;
    deploy)
        deploy_actions
        ;;
    *)
        echo "Usage: $0 {test|events|verify|estimate|deploy}"
        echo ""
        echo "Commands:"
        echo "  test <address> <balance> <bonus>  - Test autopush for single user"
        echo "  events                            - Check Flow Actions events"
        echo "  verify <address>                  - Verify user received GUM"
        echo "  estimate <user_count>             - Estimate gas cost for batch"
        echo "  deploy                            - Deploy Flow Actions integration"
        echo ""
        echo "Examples:"
        echo "  $0 test 0x1234... 50.0 100.0"
        echo "  $0 events"
        echo "  $0 verify 0x1234..."
        echo "  $0 estimate 1000"
        exit 1
        ;;
esac
