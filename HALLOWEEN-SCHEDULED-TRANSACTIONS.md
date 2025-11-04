# 🎃 Halloween GumDrop - Automated Scheduling Guide

## ✅ What You Now Have

Flow's **Scheduled Transactions** feature lets you set up the Halloween drop to activate **automatically** on Oct 31, 2025 at 12:01 AM EST - no need to manually trigger it!

---

## 📦 Files Created

1. **`cadence/contracts/HalloweenDropHandler.cdc`** ✅  
   - Already exists
   - Defines what code runs when scheduled time arrives
   - Calls `FlunksGumDrop.Admin.startDrop()` with Halloween parameters

2. **`cadence/transactions/init-halloween-handler.cdc`** ✅  
   - Initializes the handler resource
   - Run ONCE before scheduling

3. **`cadence/transactions/schedule-halloween-drop.cdc`** ✅  
   - Schedules the transaction to run at future time
   - Handles fee estimation and payment
   - Uses FlowTransactionScheduler on mainnet

4. **`setup-scheduled-halloween-drop.sh`** ✅  
   - Automated setup script
   - Deploys contract, initializes handler, schedules execution

---

## 🚀 How to Set It Up

### Option 1: Automated (Recommended)
```bash
cd ~/Desktop/flunks.flow
./setup-scheduled-halloween-drop.sh
```

This will:
1. Deploy `HalloweenDropHandler` contract to mainnet
2. Initialize the handler resource
3. Calculate delay until Oct 31, 12:01 AM EST
4. Schedule the transaction
5. Pay the scheduling fees

### Option 2: Manual Steps
```bash
# 1. Deploy the contract
flow accounts add-contract HalloweenDropHandler \
  ./cadence/contracts/HalloweenDropHandler.cdc \
  --network mainnet \
  --signer mainnet-account

# 2. Initialize the handler
flow transactions send ./cadence/transactions/init-halloween-handler.cdc \
  --network mainnet \
  --signer mainnet-account

# 3. Schedule the drop (delay in seconds)
# For Oct 31, 2025: ~648,000 seconds from now (adjust as needed)
flow transactions send ./cadence/transactions/schedule-halloween-drop.cdc \
  --network mainnet \
  --signer mainnet-account \
  --args-json '[
    {"type":"UFix64","value":"648000.0"},
    {"type":"UInt8","value":"0"},
    {"type":"UInt64","value":"1000"}
  ]'
```

---

## 💰 Cost

**Scheduling Fee**: ~0.001-0.01 FLOW (paid once upfront)
- Covers the gas for the future `startDrop()` transaction
- Automatically deducted when you schedule it

---

## ✨ What Happens

### Before Oct 31:
- Contract deployed ✅
- Handler initialized ✅
- Transaction scheduled ✅
- **You don't need to do anything else**

### Oct 31, 2025 at 12:01 AM EST:
- Flow blockchain automatically executes your handler
- `FlunksGumDrop.Admin.startDrop()` is called
- Drop becomes active for 72 hours
- Users can claim 100 GUM per Flunks NFT

### Nov 3, 2025 at 12:01 AM EST:
- Drop automatically ends (endTime enforcement in contract)

---

## 🔍 Verify It's Scheduled

After running the setup, you can check your scheduled transactions:

```bash
# Query your account's scheduled transactions
flow scripts execute \
  --network mainnet \
  --code '
    import FlowTransactionSchedulerUtils from 0x0fd0e3a13a5e9142
    
    access(all) fun main(address: Address): [AnyStruct] {
      let acct = getAccount(address)
      let managerRef = acct.capabilities.borrow<&{FlowTransactionSchedulerUtils.Manager}>(/public/FlowTransactionSchedulerManager)
        ?? panic("No manager found")
      return managerRef.getAllScheduledTransactions()
    }
  ' \
  --arg Address:0x807c3d470888cc48
```

---

## 🎯 Testing First

Want to test before Oct 31? Use a short delay:

```bash
# Schedule to run in 60 seconds (testing)
flow transactions send ./cadence/transactions/schedule-halloween-drop.cdc \
  --network mainnet \
  --signer mainnet-account \
  --args-json '[
    {"type":"UFix64","value":"60.0"},
    {"type":"UInt8","value":"1"},
    {"type":"UInt64","value":"1000"}
  ]'
```

Then check FlunksGumDrop status after 1 minute:
```bash
flow scripts execute ./cadence/scripts/check-halloween-drop-status.cdc --network mainnet
```

---

## ❓ FAQ

**Q: What if I want to cancel the scheduled transaction?**  
A: You can cancel using the FlowTransactionScheduler Manager:
```cadence
transaction(txID: UInt64) {
  prepare(signer: auth(Storage) &Account) {
    let manager = signer.storage.borrow<&FlowTransactionSchedulerUtils.Manager>(...)
    manager.cancel(id: txID)
  }
}
```

**Q: What if the scheduled time passes and I haven't set it up?**  
A: No problem! You can still manually trigger using your existing script:
```bash
./halloween-airdrop.sh
```

**Q: Can I schedule multiple drops?**  
A: Yes! Each scheduled transaction gets a unique ID. You could schedule:
- Halloween drop (Oct 31)
- Thanksgiving drop (Nov 28)
- Holiday drop (Dec 25)
- etc.

---

## 🎉 Summary

### Before Scheduled Transactions:
❌ Need to wake up at 12:01 AM EST on Oct 31  
❌ Manually run command  
❌ Hope nothing goes wrong  

### With Scheduled Transactions:
✅ Set it and forget it  
✅ Blockchain handles execution  
✅ Sleep peacefully on Halloween night  

**Run `./setup-scheduled-halloween-drop.sh` and you're done!** 🎃
