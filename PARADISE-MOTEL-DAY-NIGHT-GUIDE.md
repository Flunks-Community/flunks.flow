# Paradise Motel Day/Night Dynamic Images
## Using Forte Upgrade with Supabase Integration

---

## 🌅 Overview

Your Paradise Motel NFTs now have **dynamic day/night images** that change every 12 hours based on each user's local timezone. The system leverages:
- **Forte Upgrade**: Cadence's enhanced dynamic metadata capabilities
- **SemesterZero.UserProfile**: Existing timezone tracking (6 AM - 6 PM = day)
- **Supabase**: Your existing image timing logic
- **ParadiseMotel Contract**: New dedicated contract for dynamic resolution

---

## ⏰ How It Works

### 12-Hour Cycles
```
DAY:   6 AM  →  6 PM  (12 hours)
NIGHT: 6 PM  →  6 AM  (12 hours)
```

### User Flow
1. **User visits mylocker** → Website calls FCL script
2. **Script checks `UserProfile.isDaytime()`** → Calculates local time
3. **Returns correct image URI** → Day or night version
4. **Website renders dynamic image** → Updates every hour

### Architecture
```
┌─────────────────────────────────────────────────────────┐
│              Paradise Motel NFT Owner                    │
│            (Has UserProfile with timezone)               │
└────────────────────────┬────────────────────────────────┘
                         │
                         │ 1. Website calls script
                         ↓
┌─────────────────────────────────────────────────────────┐
│         ParadiseMotel.getCurrentImageForSupabase()       │
│                                                          │
│  ✓ Reads UserProfile.isDaytime()                        │
│  ✓ Returns dayImageURI or nightImageURI                 │
│  ✓ Includes timeContext, localHour, timezone            │
└────────────────────────┬────────────────────────────────┘
                         │
                         │ 2. Returns JSON response
                         ↓
┌─────────────────────────────────────────────────────────┐
│                 Your Website (mylocker)                  │
│                                                          │
│  ✓ Displays correct image (day or night)                │
│  ✓ Can cache result for 1 hour                          │
│  ✓ Syncs with Supabase image URLs                       │
└─────────────────────────────────────────────────────────┘
```

---

## 🎯 Paradise Motel Contract

Located at: `cadence/contracts/ParadiseMotel.cdc`

### Key Functions

#### 1. **resolveParadiseMotelImage()**
Resolves the correct image based on owner's local time:
```cadence
ParadiseMotel.resolveParadiseMotelImage(
    ownerAddress: 0x1234...,
    dayImageURI: "ipfs://day-room-101",
    nightImageURI: "ipfs://night-room-101"
)
// Returns: "ipfs://day-room-101" if 6 AM - 6 PM local time
// Returns: "ipfs://night-room-101" if 6 PM - 6 AM local time
```

#### 2. **getCurrentImageForSupabase()**
Returns full metadata for Supabase integration:
```cadence
ParadiseMotel.getCurrentImageForSupabase(
    ownerAddress: 0x1234...,
    dayImageURI: "https://flunks.io/motel/day/room-101.png",
    nightImageURI: "https://flunks.io/motel/night/room-101.png"
)

// Response:
{
    "imageURI": "https://flunks.io/motel/day/room-101.png",
    "timeContext": "day",
    "isDaytime": true,
    "localHour": 14,
    "timezone": -5,
    "hasProfile": true
}
```

#### 3. **batchGetTimeContext()**
Get day/night status for multiple users at once:
```cadence
ParadiseMotel.batchGetTimeContext(
    addresses: [0x1234..., 0x5678..., 0x9abc...]
)

// Response:
[
    {
        "address": "0x1234...",
        "isDaytime": true,
        "localHour": 10,
        "timezone": -5,
        "timeContext": "day"
    },
    {
        "address": "0x5678...",
        "isDaytime": false,
        "localHour": 22,
        "timezone": 8,
        "timeContext": "night"
    }
]
```

---

## 📜 Scripts

### 1. Get Single User's Image
**File**: `cadence/scripts/paradise-motel-get-image.cdc`

```bash
flow scripts execute cadence/scripts/paradise-motel-get-image.cdc \
  --arg Address:0x1234567890abcdef \
  --arg String:"https://flunks.io/motel/day/room-101.png" \
  --arg String:"https://flunks.io/motel/night/room-101.png" \
  --network testnet
```

### 2. Batch Check Multiple Users
**File**: `cadence/scripts/paradise-motel-batch-time-context.cdc`

```bash
flow scripts execute cadence/scripts/paradise-motel-batch-time-context.cdc \
  --arg Address:[0x1234...,0x5678...,0x9abc...] \
  --network testnet
```

### 3. Check Timezone (Testing)
**File**: `cadence/scripts/paradise-motel-check-timezone.cdc`

```bash
flow scripts execute cadence/scripts/paradise-motel-check-timezone.cdc \
  --arg Int:-5 \
  --network testnet
```

---

## 🌐 Website Integration

### API Route (Next.js)
**File**: `app/api/paradise-motel/image/route.ts`

```typescript
import * as fcl from "@onflow/fcl"

// Configure FCL
fcl.config()
  .put("accessNode.api", "https://rest-testnet.onflow.org")
  .put("flow.network", "testnet")

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url)
  const ownerAddress = searchParams.get("owner")
  const dayImageURI = searchParams.get("dayImage")
  const nightImageURI = searchParams.get("nightImage")

  if (!ownerAddress || !dayImageURI || !nightImageURI) {
    return Response.json({ error: "Missing parameters" }, { status: 400 })
  }

  try {
    const result = await fcl.query({
      cadence: `
        import ParadiseMotel from 0xYOUR_CONTRACT_ADDRESS
        
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
        arg(ownerAddress, t.Address),
        arg(dayImageURI, t.String),
        arg(nightImageURI, t.String)
      ]
    })

    // Cache for 1 hour
    return Response.json(result, {
      headers: {
        "Cache-Control": "public, max-age=3600"
      }
    })
  } catch (error) {
    console.error("Paradise Motel image error:", error)
    return Response.json(
      { error: "Failed to resolve image" },
      { status: 500 }
    )
  }
}
```

### Frontend Component (React)
```typescript
import { useEffect, useState } from "react"

interface ParadiseMotelImageProps {
  ownerAddress: string
  nftId: number
  dayImageURI: string
  nightImageURI: string
}

export function ParadiseMotelImage({
  ownerAddress,
  nftId,
  dayImageURI,
  nightImageURI
}: ParadiseMotelImageProps) {
  const [imageData, setImageData] = useState<any>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function fetchImage() {
      try {
        const params = new URLSearchParams({
          owner: ownerAddress,
          dayImage: dayImageURI,
          nightImage: nightImageURI
        })
        
        const res = await fetch(`/api/paradise-motel/image?${params}`)
        const data = await res.json()
        setImageData(data)
      } catch (error) {
        console.error("Failed to fetch Paradise Motel image:", error)
      } finally {
        setLoading(false)
      }
    }

    fetchImage()
    
    // Refresh every hour
    const interval = setInterval(fetchImage, 3600000)
    return () => clearInterval(interval)
  }, [ownerAddress, dayImageURI, nightImageURI])

  if (loading) {
    return <div>Loading Paradise Motel...</div>
  }

  return (
    <div className="paradise-motel-nft">
      <img 
        src={imageData?.imageURI} 
        alt={`Paradise Motel Room #${nftId}`}
        className={`motel-image ${imageData?.timeContext}`}
      />
      <div className="time-indicator">
        {imageData?.isDaytime ? "🌅 Day" : "🌙 Night"}
        <span className="local-time">
          {imageData?.localHour}:00 (Local Time)
        </span>
      </div>
    </div>
  )
}
```

---

## 🗄️ Supabase Integration

### Table: `paradise_motel_images`
```sql
CREATE TABLE paradise_motel_images (
  id BIGSERIAL PRIMARY KEY,
  nft_id INTEGER NOT NULL,
  room_number INTEGER,
  day_image_uri TEXT NOT NULL,
  night_image_uri TEXT NOT NULL,
  level VARCHAR(50) DEFAULT 'Paradise Motel',
  special_features JSONB,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_nft_id ON paradise_motel_images(nft_id);
```

### Sync with Blockchain
You can create a cron job to log which image is shown:

```sql
-- Track image displays
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
CREATE INDEX idx_displayed_at ON paradise_motel_image_logs(displayed_at);
```

---

## 🚀 Deployment Steps

### 1. Deploy ParadiseMotel Contract
```bash
# Testnet
flow accounts add-contract ParadiseMotel \
  ./cadence/contracts/ParadiseMotel.cdc \
  --network testnet \
  --signer your-testnet-account

# Mainnet
flow accounts add-contract ParadiseMotel \
  ./cadence/contracts/ParadiseMotel.cdc \
  --network mainnet \
  --signer your-mainnet-account
```

### 2. Upload Images to IPFS/CDN
```
Day Images:
- https://flunks.io/paradise-motel/day/room-101.png
- https://flunks.io/paradise-motel/day/room-102.png
- ...

Night Images:
- https://flunks.io/paradise-motel/night/room-101.png
- https://flunks.io/paradise-motel/night/room-102.png
- ...
```

### 3. Seed Supabase
```sql
INSERT INTO paradise_motel_images (nft_id, room_number, day_image_uri, night_image_uri)
VALUES
  (1, 101, 'https://flunks.io/paradise-motel/day/room-101.png', 'https://flunks.io/paradise-motel/night/room-101.png'),
  (2, 102, 'https://flunks.io/paradise-motel/day/room-102.png', 'https://flunks.io/paradise-motel/night/room-102.png');
```

### 4. Deploy API Route
```bash
cd your-website
npm run build
vercel --prod
```

### 5. Test on Testnet
```bash
# Check a specific user
flow scripts execute cadence/scripts/paradise-motel-get-image.cdc \
  --arg Address:0x1234567890abcdef \
  --arg String:"https://flunks.io/paradise-motel/day/room-101.png" \
  --arg String:"https://flunks.io/paradise-motel/night/room-101.png" \
  --network testnet
```

---

## 🎨 Image Naming Convention

### Recommended Structure
```
paradise-motel/
  day/
    room-101.png
    room-102.png
    suite-201.png
  night/
    room-101.png
    room-102.png
    suite-201.png
```

### Metadata Attributes
Each Paradise Motel NFT should have:
```json
{
  "nftId": 1,
  "roomNumber": 101,
  "level": "Paradise Motel",
  "dayImageURI": "https://flunks.io/paradise-motel/day/room-101.png",
  "nightImageURI": "https://flunks.io/paradise-motel/night/room-101.png",
  "specialFeatures": ["Ocean View", "Mini Bar", "24hr Room Service"]
}
```

---

## 📊 Performance Considerations

### Caching Strategy
- **Client-side**: Cache image data for 1 hour
- **CDN**: Serve images from CDN with long cache headers
- **API**: Return `Cache-Control: public, max-age=3600`

### Batch Operations
For gallery views with many NFTs:
```typescript
// Instead of N individual calls, use batch script
const addresses = nfts.map(nft => nft.owner)
const timeContexts = await fcl.query({
  cadence: batchTimeContextScript,
  args: (arg, t) => [arg(addresses, t.Array(t.Address))]
})
```

### Vercel Edge Function
Deploy the API as an Edge Function for global low-latency:
```typescript
// app/api/paradise-motel/image/route.ts
export const runtime = 'edge'
```

---

## 🔍 Debugging

### Check User's Timezone
```bash
flow scripts execute cadence/scripts/get-user-profile.cdc \
  --arg Address:0x1234567890abcdef \
  --network testnet
```

### Manually Test Timezone Logic
```bash
flow scripts execute cadence/scripts/paradise-motel-check-timezone.cdc \
  --arg Int:-5 \
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

## 📈 Analytics

Track image switches in Supabase:

```sql
-- How many users see day vs night right now
SELECT 
  time_context,
  COUNT(*) as user_count
FROM paradise_motel_image_logs
WHERE displayed_at > NOW() - INTERVAL '1 hour'
GROUP BY time_context;

-- Most active timezones
SELECT 
  timezone,
  COUNT(DISTINCT owner_address) as users
FROM paradise_motel_image_logs
GROUP BY timezone
ORDER BY users DESC
LIMIT 10;
```

---

## 🎃 Next Steps

1. **Deploy ParadiseMotel.cdc** to testnet
2. **Upload day/night images** to IPFS or CDN
3. **Create API route** in your website
4. **Test with your account** on mylocker
5. **Deploy to mainnet** for production

Your existing Supabase image timing logic now integrates seamlessly with the blockchain using Forte's dynamic metadata capabilities! 🚀

---

## 💡 Key Benefits

✅ **True Dynamic NFTs**: Images change automatically every 12 hours  
✅ **Personalized**: Based on each user's local timezone  
✅ **Efficient**: Leverages existing `UserProfile` infrastructure  
✅ **Scalable**: Batch operations for gallery views  
✅ **Integrated**: Works with your existing Supabase system  
✅ **Forte Powered**: Uses latest Cadence capabilities  

🌅 Welcome to Paradise Motel — where day becomes night! 🌙
