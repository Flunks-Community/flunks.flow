# SemesterZero Contract - Feature Comparison

## 📊 What's Where

### ✅ SemesterZero_Hackathon.cdc (Main Contract)
**Status**: Ready for deployment to mainnet

**Features Included:**
1. ✅ **GumDrop System**
   - 72-hour claim window
   - `Admin.startDrop(startTime, endTime, gumPerFlunk)`
   - `Admin.endDrop()` 
   - `isEligibleForGumDrop()`
   - Events: GumDropCreated, GumDropClaimed, GumDropClosed

2. ✅ **UserProfile System**
   - Stores username + timezone offset
   - `createUserProfile(username, timezone)`
   - `getLocalHour()` - calculates user's local time
   - `isDaytime()` - returns true if 6 AM - 6 PM in user's timezone

3. ✅ **Chapter 5 NFT System**
   - `registerSlackerCompletion()`
   - `registerOverachieverCompletion()`
   - `airdropChapter5NFT()`
   - **NEW**: `serialNumber` field (mint order 1, 2, 3...)
   - **NEW**: `reveal()` function to update metadata later
   - Events: Chapter5SlackerCompleted, Chapter5OverachieverCompleted, Chapter5NFTMinted

4. ✅ **Chapter5NFT Resource**
   - Name: "Paradise Motel"
   - Collection: "Flunks: Semester Zero"
   - Metadata: serialNumber, revealed flag, image URL
   - Implements NonFungibleToken.NFT + MetadataViews.Display

---

### 🆚 ParadiseMotel.cdc (Separate Contract)
**Status**: Exists but NOT deployed to mainnet

**Features:**
- `resolveParadiseMotelImage()` - Returns day/night image based on timezone
- `isDaytimeForTimezone()` - Helper function
- Day/Night constants (6 AM - 6 PM = day)
- Events for image switching

**PROBLEM**: This is a **separate contract** that references `SemesterZero`

**Options:**
1. **Deploy ParadiseMotel.cdc** as separate contract to mainnet
2. **Merge Paradise Motel functions** into SemesterZero_Hackathon.cdc
3. **Use existing functions** - SemesterZero already has `UserProfile.isDaytime()`!

---

### 🧪 TestPumpkinDrop420.cdc (Old Test Version)
**Status**: Deployed to mainnet at 0x807c3d470888cc48

**What it has:**
- Same GumDrop system as SemesterZero
- Same Chapter 5 system as SemesterZero
- **BUT**: Missing serialNumber + reveal features
- **BUT**: Missing your latest NFT metadata updates

**This was your TEST contract** - SemesterZero is the upgraded version!

---

## 🎯 For Hackathon: What You ACTUALLY Need

### Option A: Use SemesterZero Only (Simplest)
**Deploy**: `SemesterZero_Hackathon.cdc` to mainnet

**Has Everything You Need:**
1. ✅ GumDrop (72-hour window, manual trigger)
2. ✅ UserProfile (timezone storage)
3. ✅ `UserProfile.isDaytime()` (built-in!)
4. ✅ Chapter 5 NFT with serialNumber
5. ✅ Reveal system

**Day/Night Images**: Use frontend to call `SemesterZero.UserProfile.isDaytime()` and switch images in React

**Example:**
```typescript
const isDaytime = await fcl.query({
  cadence: `
    import SemesterZero from 0x807c3d470888cc48
    
    access(all) fun main(userAddress: Address): Bool {
      let profileRef = getAccount(userAddress)
        .capabilities.get<&SemesterZero.UserProfile>(SemesterZero.UserProfilePublicPath)
        .borrow()
      
      return profileRef?.isDaytime() ?? true
    }
  `,
  args: (arg, t) => [arg(userAddress, t.Address)]
})

const image = isDaytime 
  ? '/images/paradise-motel-day.png'
  : '/images/paradise-motel-night.png'
```

---

### Option B: Deploy Both (More Modular)
**Deploy**:
1. `SemesterZero_Hackathon.cdc` (core features)
2. `ParadiseMotel.cdc` (day/night image resolver)

**Benefit**: Cleaner separation of concerns

**Downside**: More contracts to maintain

---

## 📝 What's in SemesterZero vs TestPumpkin

| Feature | TestPumpkinDrop420 | SemesterZero_Hackathon |
|---------|-------------------|------------------------|
| GumDrop System | ✅ | ✅ |
| UserProfile + Timezone | ✅ | ✅ |
| Chapter 5 NFT | ✅ | ✅ |
| **serialNumber** (mint order) | ❌ | ✅ **NEW** |
| **reveal()** function | ❌ | ✅ **NEW** |
| NFT Name "Paradise Motel" | ❌ | ✅ **NEW** |
| Collection "Flunks: Semester Zero" | ❌ | ✅ **NEW** |
| Paradise Motel day/night | ❌ | ✅ (via UserProfile) |
| Deployed to Mainnet | ✅ (old) | ❌ (needs deploy) |

---

## 🚀 Deployment Plan for Hackathon

### Step 1: Update flow.json
Add SemesterZero to mainnet deployments:
```json
"mainnet": {
  "mainnet-account": [
    "Flunks",
    "SemesterZero"  // <-- ADD THIS
  ]
}
```

### Step 2: Remove/Comment Out Broken Contract
```json
"mainnet": {
  "mainnet-account": [
    "Flunks",
    "SemesterZero"
    // "HalloweenDropHandler"  // <-- COMMENT OUT (broken import)
  ]
}
```

### Step 3: Deploy
```bash
flow project deploy --network=mainnet --update
```

This will:
- ✅ Deploy SemesterZero_Hackathon.cdc with ALL your latest features
- ✅ Keep existing Flunks contract unchanged
- ✅ Skip HalloweenDropHandler (broken)

---

## 🎨 Day/Night Image System

### Current Implementation (SemesterZero)
Users have `UserProfile` with timezone → `isDaytime()` calculates if it's 6 AM - 6 PM

### How to Use:

**Frontend (React/Next.js):**
```typescript
// Query user's day/night status
const { isDaytime, localHour } = await fcl.query({
  cadence: `
    import SemesterZero from 0x807c3d470888cc48
    
    access(all) fun main(userAddress: Address): {String: AnyStruct} {
      let profile = getAccount(userAddress)
        .capabilities.get<&SemesterZero.UserProfile>(SemesterZero.UserProfilePublicPath)
        .borrow()
        ?? panic("No profile")
      
      return {
        "isDaytime": profile.isDaytime(),
        "localHour": profile.getLocalHour(),
        "timezone": profile.timezone
      }
    }
  `
})

// Display correct image
<img src={isDaytime ? dayImage : nightImage} />
```

**Already working!** You used this for the ambient sounds system.

---

## ✅ ANSWER: Is Everything Ready?

### YES ✅ - SemesterZero has ALL features:
1. ✅ GumDrop (manual trigger Oct 31)
2. ✅ UserProfile with timezone
3. ✅ Day/Night detection (`isDaytime()`)
4. ✅ Chapter 5 NFT with serialNumber
5. ✅ Reveal system for later
6. ✅ NFT metadata updated ("Paradise Motel", "Flunks: Semester Zero")

### Just Need To:
1. **Deploy SemesterZero to mainnet**
2. **Upload unrevealed NFT image**
3. **Test the flow end-to-end**

### ParadiseMotel.cdc is OPTIONAL
You can use it if you want a separate contract for image resolution, but **SemesterZero already has `UserProfile.isDaytime()`** which does the same thing!

---

## 🎯 Recommendation

**Use SemesterZero_Hackathon.cdc ONLY**

It has everything TestPumpkinDrop had, plus:
- Serial numbers
- Reveal system
- Updated NFT branding

Deploy it and you're ready for the hackathon! 🚀
