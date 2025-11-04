# 🚀 Testnet Deployment Guide — Step-by-Step

**Target**: Flow Testnet  
**Features**: Halloween Airdrop, Paradise Motel Day/Night, GUM System  
**Estimated Time**: 30-45 minutes

---

## 📋 Prerequisites

Before you start, make sure you have:

- [ ] Flow CLI installed (`flow version`)
- [ ] Testnet account configured in `flow.json`
- [ ] Testnet account funded (get free FLOW from faucet)
- [ ] All 3 contracts ready (SemesterZero, SemesterZeroFlowActions, ParadiseMotel)

---

## Step 1: Verify Your Testnet Account

```bash
# Check your testnet account
flow accounts get --network testnet

# Expected output:
# Account: 0xYOUR_ADDRESS
# Balance: X.XXXX FLOW
# Contracts: [list of contracts]
```

**If you don't have a testnet account:**
```bash
# Generate new keys
flow keys generate

# Create testnet account at: https://testnet-faucet.onflow.org/
# Or use: flow accounts create
```

**If you need testnet FLOW:**
- Visit: https://testnet-faucet.onflow.org/
- Enter your address
- Get 1000 FLOW (free)

---

## Step 2: Check if SemesterZero is Already Deployed

```bash
# View your account details
flow accounts get YOUR_ADDRESS --network testnet

# Look for "Contracts:" section
# If you see "SemesterZero" listed, it's already deployed
```

### Option A: SemesterZero Already Deployed (Update It)

```bash
flow accounts update-contract SemesterZero \
  ./cadence/contracts/SemesterZero.cdc \
  --network testnet \
  --signer your-testnet-account

# ⏳ Wait for confirmation...
# ✅ "Contract updated successfully"
```

### Option B: SemesterZero Not Deployed (Deploy Fresh)

```bash
flow accounts add-contract SemesterZero \
  ./cadence/contracts/SemesterZero.cdc \
  --network testnet \
  --signer your-testnet-account

# ⏳ Wait for confirmation...
# ✅ "Contract deployed successfully"
```

**Verify it worked:**
```bash
flow accounts get YOUR_ADDRESS --network testnet | grep SemesterZero
# Should show: SemesterZero
```

---

## Step 3: Deploy SemesterZeroFlowActions

```bash
flow accounts add-contract SemesterZeroFlowActions \
  ./cadence/contracts/SemesterZeroFlowActions.cdc \
  --network testnet \
  --signer your-testnet-account

# ⏳ Wait for confirmation...
# ✅ "Contract deployed successfully"
```

**Verify:**
```bash
flow accounts get YOUR_ADDRESS --network testnet | grep SemesterZeroFlowActions
# Should show: SemesterZeroFlowActions
```

**If you get an error:**
- Check that SemesterZero deployed first (Step 2)
- Verify imports point to correct address
- Make sure you have enough FLOW for gas

---

## Step 4: Deploy ParadiseMotel

```bash
flow accounts add-contract ParadiseMotel \
  ./cadence/contracts/ParadiseMotel.cdc \
  --network testnet \
  --signer your-testnet-account

# ⏳ Wait for confirmation...
# ✅ "Contract deployed successfully"
```

**Verify:**
```bash
flow accounts get YOUR_ADDRESS --network testnet | grep ParadiseMotel
# Should show: ParadiseMotel
```

---

## Step 5: View All Deployed Contracts

```bash
flow accounts get YOUR_ADDRESS --network testnet

# Should see:
# Contracts:
#   - SemesterZero
#   - SemesterZeroFlowActions
#   - ParadiseMotel
#   - [any other contracts you have]
```

**🎉 All 3 contracts deployed!** Now let's test them.

---

## Step 6: Test Halloween Airdrop (Flow Actions)

### Test 6A: Check Eligibility

```bash
flow scripts execute cadence/scripts/check-autopush-eligibility.cdc \
  --arg Address:YOUR_ADDRESS \
  --network testnet

# Expected output:
# {
#   "hasGumAccount": true/false,
#   "currentBalance": X.XX,
#   "hasProfile": true/false,
#   "isDaytime": true/false
# }
```

**If hasGumAccount is false**, you need to create one first:
```bash
# Create GumAccount (if needed)
flow transactions send cadence/transactions/setup-gum-account.cdc \
  --network testnet \
  --signer your-testnet-account
```

### Test 6B: Autopush Single User (Manual Test)

```bash
# Using helper script (recommended)
./halloween-flow-actions.sh

# Choose option 2: Autopush single user
# Enter user address: YOUR_ADDRESS
# Enter Supabase balance: 50.0
# Enter Halloween bonus: 10.0
# Enter workflow ID: test-workflow-001

# ⏳ Transaction processing...
# ✅ GUM autopushed successfully!
```

**Or directly:**
```bash
flow transactions send cadence/transactions/flow-actions-autopush.cdc \
  --arg Address:YOUR_ADDRESS \
  --arg UFix64:50.0 \
  --arg UFix64:10.0 \
  --arg String:"test-workflow-001" \
  --network testnet \
  --signer your-testnet-account
```

### Test 6C: Verify GUM Balance Increased

```bash
flow scripts execute cadence/scripts/check-autopush-eligibility.cdc \
  --arg Address:YOUR_ADDRESS \
  --network testnet

# currentBalance should now be 60.0 (50 + 10 bonus)
```

### Test 6D: View Events

```bash
flow events get A.YOUR_ADDRESS.SemesterZero.GumSynced \
  --network testnet \
  --start RECENT_BLOCK \
  --end CURRENT_BLOCK

# Should show GumSynced event with:
#   - account: YOUR_ADDRESS
#   - amount: 60.0
#   - source: "flow-actions"
```

**🎃 Halloween Airdrop works!** Flow Actions successfully synced GUM.

---

## Step 7: Test Paradise Motel Day/Night

### Test 7A: Test Timezone Calculation

```bash
# Using helper script (recommended)
./paradise-motel.sh

# Choose option 3: Test timezone calculation
# Enter timezone offset: -5 (EST)

# Expected output:
# {
#   "timezone": -5,
#   "isDaytime": true/false,
#   "localHour": X,
#   "timeContext": "day" or "night"
# }
```

**Or directly:**
```bash
# Test EST (-5)
flow scripts execute cadence/scripts/paradise-motel-check-timezone.cdc \
  --arg Int:-5 \
  --network testnet

# Test PST (-8)
flow scripts execute cadence/scripts/paradise-motel-check-timezone.cdc \
  --arg Int:-8 \
  --network testnet

# Test JST (+9)
flow scripts execute cadence/scripts/paradise-motel-check-timezone.cdc \
  --arg Int:9 \
  --network testnet
```

### Test 7B: Get Current Image for User

```bash
# Using helper script
./paradise-motel.sh

# Choose option 1: Get current image for a user
# Enter owner address: YOUR_ADDRESS
# Enter day image URI: https://flunks.io/motel/day/room-101.png
# Enter night image URI: https://flunks.io/motel/night/room-101.png

# Expected output:
# {
#   "imageURI": "https://flunks.io/motel/day/room-101.png",
#   "timeContext": "day",
#   "isDaytime": true,
#   "localHour": 14,
#   "timezone": -5,
#   "hasProfile": true
# }
```

**Or directly:**
```bash
flow scripts execute cadence/scripts/paradise-motel-get-image.cdc \
  --arg Address:YOUR_ADDRESS \
  --arg String:"https://flunks.io/motel/day/room-101.png" \
  --arg String:"https://flunks.io/motel/night/room-101.png" \
  --network testnet
```

### Test 7C: Batch Check Multiple Users

```bash
# Test with 3 addresses
flow scripts execute cadence/scripts/paradise-motel-batch-time-context.cdc \
  --arg "Address:[0xADDRESS1,0xADDRESS2,0xADDRESS3]" \
  --network testnet

# Returns array of time contexts for each user
```

**🌅 Paradise Motel works!** Images resolve dynamically based on time.

---

## Step 8: Test GUM System Integration

### Test 8A: Check GumAccount

```bash
# Check your GumAccount balance
flow scripts execute cadence/scripts/get-user-gum.cdc \
  --arg Address:YOUR_ADDRESS \
  --network testnet

# Should show balance from Step 6
```

### Test 8B: Check UserProfile

```bash
# Check your timezone and isDaytime
flow scripts execute cadence/scripts/get-user-profile.cdc \
  --arg Address:YOUR_ADDRESS \
  --network testnet

# Should show:
#   - timezone: X
#   - isDaytime: true/false
#   - localHour: X
```

### Test 8C: Manual GUM Sync (Admin Only)

```bash
# If you're the Admin, test manual sync
flow transactions send cadence/transactions/sync-gum-balance.cdc \
  --arg Address:TARGET_USER \
  --arg UFix64:100.0 \
  --network testnet \
  --signer your-testnet-account

# Then verify balance increased
flow scripts execute cadence/scripts/get-user-gum.cdc \
  --arg Address:TARGET_USER \
  --network testnet
```

**💰 GUM System works!** Balance tracking and syncing operational.

---

## Step 9: Run Comprehensive Tests

### Test All 3 Features Together

```bash
# 1. Halloween Airdrop
echo "Testing Halloween Airdrop..."
./halloween-flow-actions.sh
# Run all 3 options

# 2. Paradise Motel
echo "Testing Paradise Motel..."
./paradise-motel.sh
# Run all 3 options

# 3. GUM System
echo "Testing GUM System..."
flow scripts execute cadence/scripts/get-user-complete.cdc \
  --arg Address:YOUR_ADDRESS \
  --network testnet
```

### Verify Integration

All 3 systems should work together:
- ✅ GUM system provides GumAccount & UserProfile
- ✅ Halloween airdrop deposits to GumAccount
- ✅ Paradise Motel reads UserProfile for timezone

---

## Step 10: Document Your Testnet Deployment

Save your testnet addresses for reference:

```bash
# Create deployment record
cat > testnet-deployment.txt << EOF
Testnet Deployment - $(date)
===========================

Account: YOUR_ADDRESS
Network: testnet

Contracts:
1. SemesterZero: 0xYOUR_ADDRESS.SemesterZero
2. SemesterZeroFlowActions: 0xYOUR_ADDRESS.SemesterZeroFlowActions
3. ParadiseMotel: 0xYOUR_ADDRESS.ParadiseMotel

Testing URLs:
- Testnet Explorer: https://testnet.flowscan.org/account/YOUR_ADDRESS
- Testnet Faucet: https://testnet-faucet.onflow.org/

Test Results:
- Halloween Airdrop: ✅ Working
- Paradise Motel: ✅ Working
- GUM System: ✅ Working

Notes:
- All 3 features integrated successfully
- Events logging correctly
- Ready for mainnet deployment
EOF

cat testnet-deployment.txt
```

---

## 🎯 Testnet Success Checklist

- [ ] All 3 contracts deployed to testnet
- [ ] No deployment errors
- [ ] Halloween autopush works (GUM balance increases)
- [ ] Paradise Motel resolves day/night images correctly
- [ ] Timezone calculations accurate for multiple offsets
- [ ] GumAccount and UserProfile accessible
- [ ] Events emitted correctly
- [ ] Batch operations work
- [ ] Helper scripts functional
- [ ] Deployment documented

---

## 🔍 Troubleshooting

### Problem: "Contract not found" error
**Solution**: Make sure you deployed SemesterZero first (Step 2)

### Problem: "Insufficient balance" error
**Solution**: Get more testnet FLOW from faucet: https://testnet-faucet.onflow.org/

### Problem: "Import error" in contracts
**Solution**: Update import addresses to match your testnet deployment:
```cadence
import SemesterZero from 0xYOUR_ADDRESS
```

### Problem: Script returns "hasGumAccount: false"
**Solution**: Create GumAccount first:
```bash
flow transactions send cadence/transactions/setup-gum-account.cdc \
  --network testnet \
  --signer your-testnet-account
```

### Problem: "isDaytime" returns unexpected value
**Solution**: Check your UserProfile timezone:
```bash
flow scripts execute cadence/scripts/get-user-profile.cdc \
  --arg Address:YOUR_ADDRESS \
  --network testnet
```

### Problem: Events not showing up
**Solution**: Make sure you're checking the right block range:
```bash
# Get latest block
flow blocks get latest --network testnet

# Use that block number - 100 as start
flow events get A.YOUR_ADDRESS.SemesterZero.GumSynced \
  --start BLOCK_NUMBER_MINUS_100 \
  --end LATEST_BLOCK \
  --network testnet
```

---

## 📊 Monitoring Your Testnet Deployment

### View Contract on Testnet Explorer
1. Go to: https://testnet.flowscan.org/
2. Search for your address: `YOUR_ADDRESS`
3. Click "Contracts" tab
4. Should see all 3 contracts listed

### View Transactions
1. On Flowscan, click "Transactions" tab
2. See all your deployment transactions
3. Check transaction status (✅ Sealed = success)

### View Events
```bash
# Halloween airdrop events
flow events get A.YOUR_ADDRESS.SemesterZero.GumSynced \
  --network testnet \
  --start 0 \
  --end 999999999

# Paradise Motel events
flow events get A.YOUR_ADDRESS.ParadiseMotel.ImageSwitched \
  --network testnet \
  --start 0 \
  --end 999999999
```

---

## 🎉 Testnet Deployment Complete!

You've successfully deployed all 3 Forte Hackathon features to testnet:

✅ **Feature #1: Halloween Airdrop** — Flow Actions automation working  
✅ **Feature #2: Paradise Motel** — Dynamic day/night images resolving  
✅ **Feature #3: GUM System** — On-chain rewards with VirtualGumVault  

**Next Steps:**
1. Test with multiple users
2. Integrate with your website
3. Create demo video for hackathon
4. Deploy to mainnet (when ready)
5. Submit to Forte Hackathon! 🏆

---

## 📞 Quick Reference

### Deployment Commands
```bash
# SemesterZero
flow accounts update-contract SemesterZero ./cadence/contracts/SemesterZero.cdc --network testnet --signer your-testnet-account

# Flow Actions
flow accounts add-contract SemesterZeroFlowActions ./cadence/contracts/SemesterZeroFlowActions.cdc --network testnet --signer your-testnet-account

# Paradise Motel
flow accounts add-contract ParadiseMotel ./cadence/contracts/ParadiseMotel.cdc --network testnet --signer your-testnet-account
```

### Testing Commands
```bash
# Helper scripts
./halloween-flow-actions.sh
./paradise-motel.sh

# Direct testing
flow scripts execute cadence/scripts/check-autopush-eligibility.cdc --arg Address:YOUR_ADDRESS --network testnet
flow scripts execute cadence/scripts/paradise-motel-get-image.cdc --arg Address:YOUR_ADDRESS --arg String:"day.png" --arg String:"night.png" --network testnet
```

### Monitoring Commands
```bash
# View account
flow accounts get YOUR_ADDRESS --network testnet

# View events
flow events get A.YOUR_ADDRESS.SemesterZero.GumSynced --network testnet --start 0 --end 999999999

# Check balance
flow scripts execute cadence/scripts/get-user-gum.cdc --arg Address:YOUR_ADDRESS --network testnet
```

**Happy deploying! 🚀**
