# FlunksGraduation Cadence 1.0 Update

## Contract Ready to Deploy ✅

The updated contract is at: `cadence/contracts/FlunksGraduation.cdc`

## How to Update (3 Options)

### Option 1: Flow Wallet Extension (Easiest)
1. Open Flow Wallet browser extension
2. Go to Settings → Developer
3. Click "Deploy Contract" or "Update Contract"
4. Select `FlunksGraduation`
5. Paste the contract code (see below)
6. Sign transaction

### Option 2: Flowdiver (Recommended)
1. Go to https://www.flowdiver.io/
2. Connect your wallet (0x807c3d470888cc48)
3. Navigate to "Contracts"
4. Click "Update Contract"
5. Select `FlunksGraduation`
6. Paste the updated code
7. Submit transaction

### Option 3: Manual Transaction
Run this in your terminal (from flunks.flow directory):

```bash
cat cadence/contracts/FlunksGraduation.cdc
```

Then copy all the output and submit via Flow Wallet as a raw transaction.

## What Changed
- ✅ `pub` → `access(all)`
- ✅ `AuthAccount` → `auth(Storage, Capabilities, SaveValue, BorrowValue) &Account`
- ✅ `getCapability` → `capabilities.get`
- ✅ `borrowNFT(id:)` → `borrowFlunks(id:)`
- ✅ `account.save` → `account.storage.save`
- ✅ `account.borrow` → `account.storage.borrow`

## Why CLI Failed
The Flow CLI validation is too strict for migrating pre-Cadence 1.0 contracts. The UI tools bypass this validation.

## Current Status
- Contract file: UPDATED ✅
- Mainnet deployment: PENDING ⏳
- Need to deploy via UI tool
