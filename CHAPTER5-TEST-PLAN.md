# Chapter 5 NFT - Pre-Launch Checklist

## 🚨 BEFORE YOU CAN TEST

### 1. Update Contract on Mainnet
The contract has new changes (serialNumber, reveal function, etc.) that need to be deployed:

```bash
# Deploy updated contract to mainnet
flow project deploy --network=mainnet
```

**⚠️ WARNING**: This will update the live contract. Make sure all changes are tested first!

---

## 🧪 TESTING (Recommended Flow)

### Option A: Test on Testnet First
```bash
# 1. Deploy to testnet
flow project deploy --network=testnet

# 2. Run test script
./test-chapter5-airdrop.sh
```

### Option B: Test on Mainnet with Real Wallet
1. **Add test codes to Supabase**:
```sql
INSERT INTO access_code_discoveries (wallet_address, code_entered, success)
VALUES 
  ('YOUR_WALLET_ADDRESS', 'SLACKER', true),
  ('YOUR_WALLET_ADDRESS', 'CGAF', true);
```

2. **Setup Chapter 5 Collection** (if you haven't claimed GumDrop yet):
```bash
flow transactions send ./cadence/transactions/setup-chapter5-collection.cdc \
  --network=mainnet \
  --signer=your-account
```

3. **Admin registers completions**:
```bash
# Register Slacker
flow transactions send ./cadence/transactions/register-slacker-completion.cdc \
  YOUR_WALLET_ADDRESS \
  --network=mainnet \
  --signer=mainnet-account

# Register Overachiever
flow transactions send ./cadence/transactions/register-overachiever-completion.cdc \
  YOUR_WALLET_ADDRESS \
  --network=mainnet \
  --signer=mainnet-account
```

4. **Check eligibility**:
```bash
flow scripts execute <<'EOF'
import SemesterZero from 0x807c3d470888cc48

access(all) fun main(userAddress: Address): Bool {
  return SemesterZero.isEligibleForChapter5NFT(userAddress: userAddress)
}
EOF
YOUR_WALLET_ADDRESS --network=mainnet
```

5. **Airdrop NFT**:
```bash
flow transactions send ./cadence/transactions/airdrop-chapter5-nft.cdc \
  YOUR_WALLET_ADDRESS \
  --network=mainnet \
  --signer=mainnet-account
```

6. **Verify in wallet**:
```bash
flow scripts execute <<'EOF'
import SemesterZero from 0x807c3d470888cc48

access(all) fun main(userAddress: Address): [UInt64] {
  let collectionRef = getAccount(userAddress)
    .capabilities.get<&SemesterZero.Chapter5Collection>(
      SemesterZero.Chapter5CollectionPublicPath
    )
    .borrow()
    ?? panic("No collection")
  
  return collectionRef.getIDs()
}
EOF
YOUR_WALLET_ADDRESS --network=mainnet
```

---

## 📋 Current System Status

### ✅ Ready
- [x] Supabase table: `access_code_discoveries`
- [x] Supabase function: `get_chapter5_completions()`
- [x] Contract functions: `registerSlackerCompletion()`, `registerOverachieverCompletion()`, `airdropChapter5NFT()`
- [x] Transactions: All created and ready
- [x] Bulk airdrop script: `bulk-chapter5-airdrop.sh`

### ⏳ Needs Action
- [ ] **Deploy updated contract** (with serialNumber + reveal features)
- [ ] **Upload unrevealed image** to `https://storage.googleapis.com/flunks_public/nfts/paradise-motel-unrevealed.png`
- [ ] **Test end-to-end flow** (either testnet or mainnet)
- [ ] **Verify NFT shows in wallet** (Blocto, Lilico, etc.)

---

## 🎯 To Answer Your Question

> "Is it set up to where if someone has both completed right now it would populate in a new account?"

**No, not automatically.** Here's the flow:

1. **User enters codes** → Stored in Supabase ✅
2. **Admin runs bulk script** → Calls `registerSlackerCompletion()` + `registerOverachieverCompletion()` on blockchain
3. **Admin calls airdrop** → NFT minted and sent to user's wallet

**The automation missing**:
- Supabase → Blockchain sync (you'll do this manually via `bulk-chapter5-airdrop.sh`)
- User must have `Chapter5Collection` set up first (happens when they claim GumDrop)

---

## 🚀 Quick Test Commands

### Check if contract is deployed with new changes:
```bash
flow accounts get 0x807c3d470888cc48 --network=mainnet
```

### Query Supabase for test eligibility:
```sql
SELECT * FROM get_chapter5_completions();
```

### Check user's Chapter 5 status on blockchain:
```bash
flow scripts execute <<'EOF'
import SemesterZero from 0x807c3d470888cc48

access(all) fun main(userAddress: Address): AnyStruct {
  return SemesterZero.getChapter5Status(userAddress: userAddress)
}
EOF
YOUR_WALLET --network=mainnet
```

---

## ⚠️ Important Notes

1. **Contract Update**: The serialNumber field is NEW. You MUST redeploy the contract before testing.
2. **Collection Setup**: Users need `Chapter5Collection` before they can receive NFTs. They get this automatically when claiming GumDrop.
3. **Manual Process**: Right now it's manual. After Nov 3, you run the bulk script to process all eligible wallets.
4. **Order Matters**: Serial numbers are assigned in the order you run airdrops, so make sure to sort by completion time in Supabase!

---

## 🎨 Don't Forget

Upload the unrevealed image before testing! Otherwise wallets won't display the NFT properly.

Suggested unrevealed image:
- Generic Paradise Motel sign
- "Coming Soon" or mystery aesthetic
- 1000x1000px PNG
