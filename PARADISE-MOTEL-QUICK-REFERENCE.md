# Paradise Motel Day/Night — Quick Reference

## 🌅 The Basics

**12-hour cycles**: 6 AM - 6 PM = Day | 6 PM - 6 AM = Night

**Built on**: Existing `UserProfile.isDaytime()` function in SemesterZero.cdc

**Dynamic**: Images change automatically based on user's local timezone

---

## 🚀 Quick Commands

### Get Current Image for User
```bash
./paradise-motel.sh
# Choose option 1
```

Or directly:
```bash
flow scripts execute cadence/scripts/paradise-motel-get-image.cdc \
  --arg Address:0x1234567890abcdef \
  --arg String:"https://flunks.io/motel/day/room-101.png" \
  --arg String:"https://flunks.io/motel/night/room-101.png" \
  --network testnet
```

### Batch Check Multiple Users
```bash
flow scripts execute cadence/scripts/paradise-motel-batch-time-context.cdc \
  --arg Address:[0x1234...,0x5678...,0x9abc...] \
  --network testnet
```

### Test Timezone
```bash
flow scripts execute cadence/scripts/paradise-motel-check-timezone.cdc \
  --arg Int:-5 \
  --network testnet
```

---

## 📂 Files Created

### Contracts
- `cadence/contracts/ParadiseMotel.cdc` — Main day/night contract

### Scripts
- `cadence/scripts/paradise-motel-get-image.cdc` — Get single user image
- `cadence/scripts/paradise-motel-batch-time-context.cdc` — Batch check users
- `cadence/scripts/paradise-motel-check-timezone.cdc` — Test timezone logic

### Helper
- `paradise-motel.sh` — CLI helper script

### Docs
- `PARADISE-MOTEL-DAY-NIGHT-GUIDE.md` — Complete guide

---

## 🌐 Website Integration

### API Endpoint (Next.js)
```typescript
// app/api/paradise-motel/image/route.ts
import * as fcl from "@onflow/fcl"

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url)
  const owner = searchParams.get("owner")
  const dayImage = searchParams.get("dayImage")
  const nightImage = searchParams.get("nightImage")

  const result = await fcl.query({
    cadence: `
      import ParadiseMotel from 0xYOUR_ADDRESS
      
      access(all) fun main(
        ownerAddress: Address,
        dayImageURI: String,
        nightImageURI: String
      ): {String: AnyStruct} {
        return ParadiseMotel.getCurrentImageForSupabase(
          ownerAddress: ownerAddress,
          dayImageURI: dayImageURI,
          nightImageURI: nightImageURI
        )
      }
    `,
    args: (arg, t) => [
      arg(owner, t.Address),
      arg(dayImage, t.String),
      arg(nightImage, t.String)
    ]
  })

  return Response.json(result, {
    headers: { "Cache-Control": "public, max-age=3600" }
  })
}
```

### React Component
```typescript
function ParadiseMotelImage({ owner, nftId, dayImage, nightImage }) {
  const [data, setData] = useState(null)

  useEffect(() => {
    fetch(`/api/paradise-motel/image?owner=${owner}&dayImage=${dayImage}&nightImage=${nightImage}`)
      .then(res => res.json())
      .then(setData)
      
    // Refresh every hour
    const interval = setInterval(() => {
      fetch(`/api/paradise-motel/image?owner=${owner}&dayImage=${dayImage}&nightImage=${nightImage}`)
        .then(res => res.json())
        .then(setData)
    }, 3600000)
    
    return () => clearInterval(interval)
  }, [owner, dayImage, nightImage])

  return (
    <div>
      <img src={data?.imageURI} alt={`Paradise Motel #${nftId}`} />
      <div>{data?.isDaytime ? "🌅 Day" : "🌙 Night"}</div>
    </div>
  )
}
```

---

## 🗄️ Supabase Tables

### paradise_motel_images
```sql
CREATE TABLE paradise_motel_images (
  id BIGSERIAL PRIMARY KEY,
  nft_id INTEGER NOT NULL,
  room_number INTEGER,
  day_image_uri TEXT NOT NULL,
  night_image_uri TEXT NOT NULL,
  level VARCHAR(50) DEFAULT 'Paradise Motel',
  created_at TIMESTAMP DEFAULT NOW()
);
```

### paradise_motel_image_logs (optional)
```sql
CREATE TABLE paradise_motel_image_logs (
  id BIGSERIAL PRIMARY KEY,
  owner_address TEXT NOT NULL,
  nft_id INTEGER NOT NULL,
  image_uri TEXT NOT NULL,
  time_context VARCHAR(10) NOT NULL,
  local_hour INTEGER NOT NULL,
  displayed_at TIMESTAMP DEFAULT NOW()
);
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
    "address": "0x1234...",
    "isDaytime": true,
    "localHour": 10,
    "timezone": -5,
    "timeContext": "day"
  }
]
```

---

## 🎯 Deployment Checklist

- [ ] Deploy `ParadiseMotel.cdc` to testnet
- [ ] Upload day/night images to IPFS/CDN
- [ ] Seed Supabase `paradise_motel_images` table
- [ ] Create API route in website
- [ ] Test with helper script: `./paradise-motel.sh`
- [ ] Deploy API to Vercel
- [ ] Test on mylocker with your account
- [ ] Deploy to mainnet

---

## 🧪 Testing Scenarios

### Scenario 1: Day Image (10 AM Local)
```bash
# User in EST (-5 timezone) at 10 AM
flow scripts execute cadence/scripts/paradise-motel-check-timezone.cdc \
  --arg Int:-5 \
  --network testnet
# Expected: isDaytime = true, localHour = 10
```

### Scenario 2: Night Image (10 PM Local)
```bash
# User in PST (-8 timezone) at 10 PM
flow scripts execute cadence/scripts/paradise-motel-check-timezone.cdc \
  --arg Int:-8 \
  --network testnet
# Expected: isDaytime = false, localHour = 22
```

### Scenario 3: Edge Case (6 AM exactly)
```bash
# Exactly 6 AM should return DAY
# localHour >= 6 && localHour < 18
```

---

## 🔍 Debugging

### Check User Profile
```bash
flow scripts execute cadence/scripts/get-user-profile.cdc \
  --arg Address:0x1234567890abcdef \
  --network testnet
```

### View Events
```bash
flow events get A.YOUR_ADDRESS.ParadiseMotel.ImageSwitched \
  --network testnet \
  --start 12345678 \
  --end 12345789
```

---

## 💡 Key Functions

| Function | Purpose | Returns |
|----------|---------|---------|
| `resolveParadiseMotelImage()` | Get current image URI | `String` |
| `getCurrentImageForSupabase()` | Get full metadata | `{String: AnyStruct}` |
| `batchGetTimeContext()` | Check multiple users | `[{String: AnyStruct}]` |
| `isDaytimeForTimezone()` | Test timezone logic | `Bool` |

---

## ⚡ Performance Tips

1. **Cache API responses** for 1 hour (3600s)
2. **Use batch operations** for gallery views
3. **Deploy as Edge Function** for global low-latency
4. **Prefetch images** in browser for smooth transitions

---

## 🎃 Next Steps After Day/Night

1. ✅ Paradise Motel day/night images
2. ⏳ Halloween airdrop (Flow Actions)
3. ⏳ Deploy to mainnet
4. ⏳ Add more dynamic attributes (weather, seasons, etc.)

---

## 📚 Related Docs

- `PARADISE-MOTEL-DAY-NIGHT-GUIDE.md` — Full guide
- `FLOW-ACTIONS-IMPLEMENTATION-COMPLETE.md` — Halloween airdrop
- `SEMESTER-ZERO-SUMMARY.md` — SemesterZero overview

---

**🌅 Your Paradise Motel NFTs are now truly dynamic! 🌙**
