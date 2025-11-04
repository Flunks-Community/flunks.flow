# 🎉 Paradise Motel Day/Night System — COMPLETE

## ✅ Implementation Summary

Your **Paradise Motel NFTs** now have dynamic day/night images using Forte's upgrade! The system integrates seamlessly with your existing Supabase image timing logic.

---

## 📦 What Was Built

### 1. **ParadiseMotel.cdc Contract**
Located: `cadence/contracts/ParadiseMotel.cdc`

**Core Features:**
- ✅ `resolveParadiseMotelImage()` — Resolves correct image based on owner's local time
- ✅ `getCurrentImageForSupabase()` — Returns full metadata for API integration
- ✅ `batchGetTimeContext()` — Check day/night status for multiple users at once
- ✅ `isDaytimeForTimezone()` — Test timezone calculation (6 AM - 6 PM = day)
- ✅ `ParadiseMotelDisplay` struct — Enhanced display with dynamic fields

**Events Emitted:**
- `ImageSwitched` — Logs when image changes (day ↔ night)
- `DayNightCycleChecked` — Logs timezone checks

### 2. **Scripts (3 total)**
All located in `cadence/scripts/`

| Script | Purpose |
|--------|---------|
| `paradise-motel-get-image.cdc` | Get current image for single user |
| `paradise-motel-batch-time-context.cdc` | Batch check multiple users |
| `paradise-motel-check-timezone.cdc` | Test timezone logic |

### 3. **Helper Script**
`paradise-motel.sh` — Interactive CLI for managing the system

**Features:**
- Get current image for user
- Batch check time context
- Test timezone calculation
- Deploy contract
- View events

### 4. **Documentation (2 guides)**
- `PARADISE-MOTEL-DAY-NIGHT-GUIDE.md` — Complete implementation guide
- `PARADISE-MOTEL-QUICK-REFERENCE.md` — Quick commands & API examples

---

## 🌅 How It Works

### Architecture
```
User's NFT (Paradise Motel Room #101)
    ↓
UserProfile.isDaytime() checks local time
    ↓
ParadiseMotel.resolveParadiseMotelImage()
    ↓
Returns: dayImageURI (6 AM - 6 PM) OR nightImageURI (6 PM - 6 AM)
    ↓
Website displays correct image
```

### Time Logic
```cadence
// In SemesterZero.cdc (already exists)
pub fun isDaytime(): Bool {
    let localHour = self.getLocalHour()
    return localHour >= 6 && localHour < 18
}
```

### Dynamic Metadata (Forte Upgrade)
```cadence
// In ParadiseMotel.cdc (new)
pub fun resolveParadiseMotelImage(
    ownerAddress: Address,
    dayImageURI: String,
    nightImageURI: String
): String {
    let profile = getAccount(ownerAddress)
        .getCapability<&SemesterZero.UserProfile>(...)
        .borrow()!
    
    return profile.isDaytime() ? dayImageURI : nightImageURI
}
```

---

## 🚀 Quick Start

### 1. Test Locally
```bash
# Make helper script executable
chmod +x ./paradise-motel.sh

# Run interactive helper
./paradise-motel.sh

# Or test timezone directly
flow scripts execute cadence/scripts/paradise-motel-check-timezone.cdc \
  --arg Int:-5 \
  --network testnet
```

### 2. Deploy to Testnet
```bash
flow accounts add-contract ParadiseMotel \
  ./cadence/contracts/ParadiseMotel.cdc \
  --network testnet \
  --signer your-testnet-account
```

### 3. Test with Your Account
```bash
flow scripts execute cadence/scripts/paradise-motel-get-image.cdc \
  --arg Address:YOUR_ADDRESS \
  --arg String:"https://flunks.io/motel/day/room-101.png" \
  --arg String:"https://flunks.io/motel/night/room-101.png" \
  --network testnet
```

### 4. Integrate with Website
See `PARADISE-MOTEL-DAY-NIGHT-GUIDE.md` section "Website Integration"

---

## 🌐 Website Integration Example

### API Route (Next.js)
```typescript
// app/api/paradise-motel/image/route.ts
import * as fcl from "@onflow/fcl"

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url)
  const result = await fcl.query({
    cadence: `
      import ParadiseMotel from 0xYOUR_ADDRESS
      pub fun main(owner: Address, day: String, night: String): {String: AnyStruct} {
        return ParadiseMotel.getCurrentImageForSupabase(
          ownerAddress: owner,
          dayImageURI: day,
          nightImageURI: night
        )
      }
    `,
    args: (arg, t) => [
      arg(searchParams.get("owner"), t.Address),
      arg(searchParams.get("dayImage"), t.String),
      arg(searchParams.get("nightImage"), t.String)
    ]
  })
  
  return Response.json(result, {
    headers: { "Cache-Control": "public, max-age=3600" }
  })
}
```

### React Component
```typescript
function ParadiseMotelNFT({ owner, nftId, dayImage, nightImage }) {
  const [imageData, setImageData] = useState(null)
  
  useEffect(() => {
    fetch(`/api/paradise-motel/image?owner=${owner}&dayImage=${dayImage}&nightImage=${nightImage}`)
      .then(res => res.json())
      .then(setImageData)
  }, [owner, dayImage, nightImage])
  
  return (
    <div className="paradise-motel-nft">
      <img src={imageData?.imageURI} alt={`Room #${nftId}`} />
      <span>{imageData?.isDaytime ? "🌅" : "🌙"}</span>
      <p>{imageData?.localHour}:00 Local Time</p>
    </div>
  )
}
```

---

## 🗄️ Supabase Setup

### Create Tables
```sql
-- Store day/night image URIs
CREATE TABLE paradise_motel_images (
  id BIGSERIAL PRIMARY KEY,
  nft_id INTEGER NOT NULL UNIQUE,
  room_number INTEGER,
  day_image_uri TEXT NOT NULL,
  night_image_uri TEXT NOT NULL,
  level VARCHAR(50) DEFAULT 'Paradise Motel',
  created_at TIMESTAMP DEFAULT NOW()
);

-- Track image displays (optional analytics)
CREATE TABLE paradise_motel_image_logs (
  id BIGSERIAL PRIMARY KEY,
  owner_address TEXT NOT NULL,
  nft_id INTEGER NOT NULL,
  image_uri TEXT NOT NULL,
  time_context VARCHAR(10) NOT NULL, -- 'day' or 'night'
  local_hour INTEGER NOT NULL,
  timezone INTEGER NOT NULL,
  displayed_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_owner_nft ON paradise_motel_image_logs(owner_address, nft_id);
```

### Seed Data
```sql
INSERT INTO paradise_motel_images (nft_id, room_number, day_image_uri, night_image_uri)
VALUES
  (1, 101, 'https://flunks.io/motel/day/room-101.png', 'https://flunks.io/motel/night/room-101.png'),
  (2, 102, 'https://flunks.io/motel/day/room-102.png', 'https://flunks.io/motel/night/room-102.png'),
  (3, 201, 'https://flunks.io/motel/day/suite-201.png', 'https://flunks.io/motel/night/suite-201.png');
```

---

## 📊 Response Format

### getCurrentImageForSupabase()
```json
{
  "imageURI": "https://flunks.io/motel/day/room-101.png",
  "timeContext": "day",
  "isDaytime": true,
  "localHour": 14,
  "timezone": -5,
  "hasProfile": true
}
```

### batchGetTimeContext()
```json
[
  {
    "address": "0x1234567890abcdef",
    "isDaytime": true,
    "localHour": 10,
    "timezone": -5,
    "timeContext": "day"
  },
  {
    "address": "0xabcdef1234567890",
    "isDaytime": false,
    "localHour": 22,
    "timezone": 8,
    "timeContext": "night"
  }
]
```

---

## 🎯 Deployment Checklist

### Testnet
- [ ] Deploy `ParadiseMotel.cdc`
- [ ] Test with `paradise-motel.sh`
- [ ] Verify timezone calculations
- [ ] Upload day/night images to CDN
- [ ] Seed Supabase tables
- [ ] Create API route
- [ ] Test on website (mylocker)
- [ ] Check image switches at 6 AM / 6 PM

### Mainnet
- [ ] Deploy `ParadiseMotel.cdc` to mainnet
- [ ] Update API to use mainnet
- [ ] Upload production images
- [ ] Test with real user accounts
- [ ] Monitor events & analytics

---

## 🔍 Testing Scenarios

### Test 1: Daytime (10 AM)
```bash
flow scripts execute cadence/scripts/paradise-motel-check-timezone.cdc \
  --arg Int:-5 \
  --network testnet
# Expected: isDaytime = true, localHour = 10
```

### Test 2: Nighttime (10 PM)
```bash
flow scripts execute cadence/scripts/paradise-motel-check-timezone.cdc \
  --arg Int:-5 \
  --network testnet
# Expected: isDaytime = false, localHour = 22
```

### Test 3: Edge Cases
- 6:00 AM exactly → DAY (localHour >= 6)
- 5:59 AM → NIGHT (localHour < 6)
- 6:00 PM exactly → NIGHT (localHour >= 18)
- 5:59 PM → DAY (localHour < 18)

---

## 💡 Key Benefits

✅ **Truly Dynamic**: Images change automatically every 12 hours  
✅ **Personalized**: Based on each user's local timezone  
✅ **Efficient**: Leverages existing `UserProfile.isDaytime()`  
✅ **Scalable**: Batch operations for gallery views  
✅ **Integrated**: Works with Supabase image timing logic  
✅ **Forte Powered**: Uses latest Cadence dynamic metadata  
✅ **Event Tracking**: Monitor image switches on-chain  

---

## 📈 Analytics Queries

### Current Day/Night Distribution
```sql
SELECT 
  time_context,
  COUNT(*) as count
FROM paradise_motel_image_logs
WHERE displayed_at > NOW() - INTERVAL '1 hour'
GROUP BY time_context;
```

### Most Active Timezones
```sql
SELECT 
  timezone,
  COUNT(DISTINCT owner_address) as users
FROM paradise_motel_image_logs
GROUP BY timezone
ORDER BY users DESC
LIMIT 10;
```

### Image Switch Frequency
```sql
SELECT 
  nft_id,
  COUNT(*) as switches,
  COUNT(DISTINCT DATE(displayed_at)) as active_days
FROM paradise_motel_image_logs
GROUP BY nft_id
ORDER BY switches DESC;
```

---

## 🎨 Image Recommendations

### File Structure
```
paradise-motel/
  day/
    room-101.png
    room-102.png
    suite-201.png
    penthouse-301.png
  night/
    room-101.png
    room-102.png
    suite-201.png
    penthouse-301.png
```

### Naming Convention
- **Day**: Bright, sunny, vibrant colors
- **Night**: Moon, stars, neon signs, moody lighting
- **Consistency**: Same angle/composition, different lighting

### Metadata Example
```json
{
  "nftId": 1,
  "name": "Paradise Motel Room #101",
  "roomNumber": 101,
  "level": "Paradise Motel",
  "dayImageURI": "https://flunks.io/motel/day/room-101.png",
  "nightImageURI": "https://flunks.io/motel/night/room-101.png",
  "specialFeatures": ["Ocean View", "Mini Bar", "24hr Service"]
}
```

---

## 🔗 Related Systems

This Paradise Motel system works alongside:

1. **Halloween Flow Actions Airdrop** (from previous conversation)
   - Automated GUM distribution
   - Scheduled for Oct 31, 2025
   - See `FLOW-ACTIONS-IMPLEMENTATION-COMPLETE.md`

2. **SemesterZero Ecosystem**
   - UserProfile with timezone tracking
   - GumAccount for rewards
   - Achievements & progression
   - See `SEMESTER-ZERO-SUMMARY.md`

3. **Supabase Backend**
   - User data & analytics
   - Image URL management
   - Daily GUM tracking
   - See `GUMDROPS-SUPABASE-INTEGRATION.md`

---

## 🚨 Important Notes

1. **Users need UserProfile**: Without a `UserProfile`, defaults to daytime (6 AM - 6 PM UTC)
2. **Timezone format**: Integer offset from UTC (-12 to +14)
3. **Cache wisely**: API responses cached for 1 hour (images don't need to update more frequently)
4. **Batch operations**: Use `batchGetTimeContext()` for gallery views (more efficient)
5. **Event monitoring**: Track `ImageSwitched` events for analytics

---

## 📚 Documentation Files

| File | Purpose |
|------|---------|
| `PARADISE-MOTEL-DAY-NIGHT-GUIDE.md` | Complete implementation guide |
| `PARADISE-MOTEL-QUICK-REFERENCE.md` | Quick commands & examples |
| `PARADISE-MOTEL-SUMMARY.md` | This file (overview) |
| `paradise-motel.sh` | Interactive CLI helper |

---

## 🎃 What's Next?

1. ✅ **Paradise Motel Day/Night** — DONE!
2. ⏳ **Deploy to Testnet** — Test with your account
3. ⏳ **Halloween Airdrop** — Finalize Flow Actions integration
4. ⏳ **Website Integration** — Add to mylocker
5. ⏳ **Deploy to Mainnet** — Go live!

---

## 🙏 Credits

**Built with:**
- Flow Blockchain & Cadence
- Forte Upgrade (dynamic metadata)
- SemesterZero.cdc (existing timezone system)
- Supabase (image management)
- Your existing day/night image timing logic

**Integrates with:**
- UserProfile (timezone tracking)
- GumAccount (rewards system)
- Flow Actions (Halloween airdrop)

---

## 💬 Need Help?

### Run Interactive Helper
```bash
./paradise-motel.sh
```

### View Full Guide
```bash
cat PARADISE-MOTEL-DAY-NIGHT-GUIDE.md
```

### Quick Reference
```bash
cat PARADISE-MOTEL-QUICK-REFERENCE.md
```

---

## 🎉 Success!

Your Paradise Motel NFTs are now **truly dynamic** with automatic day/night images! 🌅🌙

The system:
✅ Uses Forte's upgrade for dynamic metadata  
✅ Integrates with existing timezone infrastructure  
✅ Works seamlessly with Supabase  
✅ Provides efficient batch operations  
✅ Emits events for analytics  
✅ Caches intelligently for performance  

**Welcome to Paradise Motel — where the view changes with the sun!** 🏨✨
