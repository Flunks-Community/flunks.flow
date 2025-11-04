# SemesterZero Fresh Account Deployment Guide

## Problem Solved
The original Flunks contract address (0x807c3d470888cc48) cannot be registered on the Flow token list due to Cadence 1.0 incompatibility with the FlunksGraduation contract. 

**Solution:** Deploy SemesterZero to a fresh mainnet account instead.

## Setup Steps

### 1. Get Your Fresh Account Address
```bash
# The address is linked to your fresh-mainnet-account.pkey file
# You'll need to provide this address in the next steps
```

### 2. Update flow.json
Open `flow.json` and replace `SERVICE_ACCOUNT_ADDRESS` with your actual fresh mainnet account address:

```json
"fresh-mainnet-account": {
    "address": "0xYOUR_ACTUAL_ADDRESS_HERE",
    "key": {
        "type": "file",
        "location": "fresh-mainnet-account.pkey"
    }
}
```

### 3. Deploy SemesterZero Contract
```bash
./deploy-semesterzero-fresh.sh
```

This will:
- Deploy SemesterZero to your fresh mainnet account
- Bypass the token list registration issue
- Enable full functionality for airdrops

### 4. Update Address References
After successful deployment, run:
```bash
./update-semesterzero-address.sh 0xYOUR_DEPLOYED_ADDRESS
```

This automatically updates:
- `flow.json` (account address + contract alias)
- `setup-semesterzero-collection.cdc` (import statement)
- `test-semesterzero-airdrop.sh` (transaction references)

## Testing Airdrops

### Setup a User Collection
```bash
flow transactions send setup-semesterzero-collection.cdc \
    --network mainnet \
    --signer <user-account-name>
```

### Test Chapter 5 NFT Airdrop
```bash
./test-semesterzero-airdrop.sh 0xRECIPIENT_ADDRESS
```

This will:
1. Set up the recipient's collection (if needed)
2. Mint a test Chapter 5 NFT
3. Airdrop it to the recipient

## Architecture

### Fresh Account Benefits
✅ No FlunksGraduation contract conflicts  
✅ Clean deployment for token list registration  
✅ Independent from original Flunks contract issues  
✅ Full SemesterZero functionality enabled  

### Contract Location
- **Fresh Account**: SemesterZero contract
- **Original Account** (0x807c3d470888cc48): Flunks, FlunksGumDrop, FlunksGraduation
- **Community Account** (0xbfffec679fff3a94): SimpleFlunks variants

### SemesterZero Features Available
1. **GumDrop Airdrops** - 72-hour claim windows with Flow Actions
2. **Paradise Motel** - Day/Night cycle based on user timezone
3. **Chapter 5 NFT Airdrops** - Auto-airdrop on 100% completion

## Files Created

| File | Purpose |
|------|---------|
| `deploy-semesterzero-fresh.sh` | Deploy SemesterZero to fresh account |
| `update-semesterzero-address.sh` | Update all address references |
| `setup-semesterzero-collection.cdc` | User collection setup transaction |
| `test-semesterzero-airdrop.sh` | Test airdrop functionality |

## Next Steps

1. ✅ Deploy SemesterZero to fresh account
2. ✅ Update all address references
3. 🎯 Test collection setup with your account
4. 🎯 Run test airdrop to verify functionality
5. 🎯 Configure frontend to use new SemesterZero address
6. 🎯 Begin production airdrop testing

## Frontend Configuration

Update your FCL config files:

**FCL-MAINNET-CONFIG.js**
```javascript
const SEMESTERZERO_ADDRESS = "0xYOUR_FRESH_ACCOUNT_ADDRESS"
```

## Troubleshooting

### Collection Setup Fails
- Ensure the user account has enough FLOW for transaction fees
- Verify SemesterZero contract is deployed correctly

### Airdrop Fails
- Check that admin reference exists in fresh-mainnet-account
- Verify recipient has collection set up
- Ensure fresh-mainnet-account has Admin resource

### Import Errors
- Run `update-semesterzero-address.sh` to fix references
- Check that flow.json has correct alias

---

**Status**: Ready to deploy and test  
**Date**: October 29, 2025  
**Deployment**: Fresh mainnet account strategy
