# SemesterZero Contract - Merge Strategy

**Date**: October 20, 2025  
**Goal**: Combine both SemesterZero versions for Forte Hackathon

---

## 🔍 What You Have

### **Version A: flunks-site (Existing/Deployed)**
✅ Day/Night Cycle (executeDayNightCycle, 12-hour, 6 AM - 6 PM)  
✅ Google Cloud bucket URLs (dayImageBucketURL, nightImageBucketURL)  
✅ Gum Drop Windows (openGumDropWindow, closeGumDropWindow, revealGumDrop)  
✅ Chapter 5 Completion Tracking (slacker + overachiever)  
✅ Chapter 5 NFT Airdrops (airdropChapter5NFT)  
✅ Admin resource with all management functions  

### **Version B: This Repo (New Features for Hackathon)**
✅ UserProfile with timezone (per-user timezone, isDaytime())  
✅ GumAccount (balance tracking, transfer, spend, deposit)  
✅ Halloween Claim System (HalloweenDrop, isEligibleForHalloween)  
✅ VirtualGumVault (Flow Actions integration)  
✅ Achievement NFTs  
✅ Special Drops  
✅ Airdrops  

---

## ⚠️ Key Differences

| Feature | Version A (flunks-site) | Version B (this repo) |
|---------|------------------------|----------------------|
| **Day/Night** | Global (one time for everyone) | Per-user (based on timezone) |
| **GUM** | Just drops/events | Full account system (balance, transfer) |
| **Image URLs** | Mutable bucket URLs | Static in metadata |
| **NFTs** | Chapter 5 only | Achievements + Airdrops |
| **Timezone** | None (Central Time hardcoded) | Per-user UserProfile |

---

## 🎯 Merge Strategy

### **Option 1: Keep Both Systems (Recommended for Hackathon)**

Keep Version A running on your website, deploy Version B as **new features**:

```
flunks-site continues using:
- SemesterZero (Version A) → Day/night for everyone, gum drops, Chapter 5

Forte Hackathon showcases:
- SemesterZero (Version B) → Per-user day/night, Halloween, GUM accounts
- ParadiseMotel → Dynamic metadata helper
- SemesterZeroFlowActions → Flow Actions integration
```

**Benefits:**
- ✅ Don't break existing website
- ✅ Show NEW features for hackathon
- ✅ Easy to demo side-by-side

**How:**
1. Deploy Version B to testnet with different account
2. Keep Version A running on mainnet/website
3. Show hackathon judges the NEW features (Halloween, per-user timezone, GUM system)

---

### **Option 2: Merge Into One Super Contract**

Combine ALL features from both versions:

**Features to merge:**
```cadence
access(all) contract SemesterZero {
    
    // FROM VERSION A:
    - Global day/night cycle (isCurrentlyDay, dayStartHour, nightStartHour)
    - Google Cloud buckets (dayImageBucketURL, nightImageBucketURL)
    - Gum drop windows (gumDropWindowActive, openGumDropWindow, etc.)
    - Chapter 5 tracking (Chapter5Status, registerSlackerCompletion, etc.)
    - Chapter 5 NFT airdrops
    
    // FROM VERSION B:
    - UserProfile with timezone (per-user day/night)
    - GumAccount (balance, transfer, deposit, spend)
    - Halloween claim system (HalloweenDrop)
    - VirtualGumVault (Flow Actions)
    - Achievement NFTs
    - Special drops
    - Airdrops
    
    // MERGED ADMIN:
    - All functions from both versions
}
```

**Benefits:**
- ✅ One comprehensive contract
- ✅ All features in one place
- ✅ Easier to maintain long-term

**Challenges:**
- ⚠️ Need to migrate existing website
- ⚠️ More complex testing
- ⚠️ Risk of breaking current functionality

---

## 💡 Recommendation: HYBRID APPROACH

**For Forte Hackathon (by Oct 31):**

1. **Keep Version A** running on flunks-site (don't touch it!)
   - Website continues to work
   - Users see day/night cycles
   - Gum drops continue
   - Chapter 5 works

2. **Deploy Version B** to testnet for hackathon demo
   - Show Halloween claim system
   - Show per-user timezone (Paradise Motel)
   - Show GUM account system
   - Show Flow Actions integration

3. **After hackathon**, merge gradually:
   - Migrate users to Version B
   - Deprecate Version A
   - Full feature set in one contract

---

## 🚀 Action Plan (Next 11 Days to Hackathon)

### **Week 1 (Oct 20-26): Testnet Deployment**
- [ ] Deploy SemesterZero Version B to testnet
- [ ] Deploy ParadiseMotel to testnet  
- [ ] Test Halloween claim flow
- [ ] Test per-user day/night
- [ ] Test GUM transfers
- [ ] Document all features

### **Week 2 (Oct 27-31): Hackathon Prep**
- [ ] Create demo video
- [ ] Write hackathon submission
- [ ] Prepare live demo
- [ ] Test on Oct 31 (Halloween!)
- [ ] Submit to Forte

### **Post-Hackathon: Production Merge**
- [ ] Plan migration from Version A → Version B
- [ ] Update flunks-site to use new contract
- [ ] Migrate user data
- [ ] Deprecate old contract

---

## 📊 Feature Comparison Table

| Feature | Version A (Live) | Version B (Hackathon) | Merged (Future) |
|---------|------------------|----------------------|-----------------|
| Global Day/Night | ✅ | ❌ | ✅ |
| Per-User Timezone | ❌ | ✅ | ✅ |
| GUM Drops | ✅ | ❌ | ✅ |
| GUM Accounts | ❌ | ✅ | ✅ |
| Chapter 5 NFTs | ✅ | ❌ | ✅ |
| Achievement NFTs | ❌ | ✅ | ✅ |
| Halloween Claims | ❌ | ✅ | ✅ |
| Flow Actions | ❌ | ✅ | ✅ |
| Paradise Motel | ❌ | ✅ | ✅ |

---

## 🎃 For Your Hackathon Submission

**Title**: "SemesterZero: Dynamic NFT Ecosystem with Flow Actions"

**Features to Highlight**:
1. ✨ **Per-User Day/Night Cycles** (Paradise Motel based on timezone)
2. 🎃 **Halloween Claim System** (eligibility on-chain, GUM in Supabase)
3. 💰 **GUM Account System** (transfer, deposit, spend tracking)
4. 🤖 **Flow Actions Integration** (VirtualGumVault for automation)
5. 🏆 **Achievement NFTs** (dynamic metadata)

**What Makes It Special**:
- ✅ Uses Forte upgrade (Flow Actions, dynamic metadata)
- ✅ Hybrid on-chain/off-chain architecture
- ✅ Real-world use case (existing Flunks community)
- ✅ Production-ready (deploying Oct 31)
- ✅ Innovative per-user experiences

---

## 🔧 What We Should Do NOW

**I recommend: KEEP THEM SEPARATE for now**

1. **Don't touch flunks-site SemesterZero** (Version A)
   - It's working
   - Users depend on it
   - Don't risk breaking it before hackathon

2. **Deploy Version B to testnet** (this repo)
   - Test all new features
   - Perfect for hackathon demo
   - Show innovation

3. **After hackathon wins** 🏆, merge them properly

Want me to help you:
- A) Create deployment guide for Version B (testnet)?
- B) Create a merged contract combining both?
- C) Create hackathon submission docs?

Let me know! 🚀
