# Paradise Motel Image URLs — Production Ready

**Date**: October 20, 2025  
**Status**: ✅ Images Hosted on Google Cloud Storage

---

## 🎨 Production Image URLs

### Day Image
```
https://storage.googleapis.com/flunks_public/images/paradise-motel-day.png
```

### Night Image
```
https://storage.googleapis.com/flunks_public/images/paradise-motel-night.png
```

**Bucket**: `flunks_public`  
**Path**: `images/`  
**Access**: Public (already configured)

---

## ✅ Ready to Use!

These URLs are already live and can be used immediately in:
1. Testnet testing
2. Supabase configuration
3. Website API
4. NFT metadata

---

## 🚀 Quick Test Commands

### Test on Testnet (After Deployment)

```bash
# Test with paradise-motel.sh
./paradise-motel.sh

# Choose option 1: Get current image for a user
# Enter owner address: YOUR_TESTNET_ADDRESS
# Enter day image URI: https://storage.googleapis.com/flunks_public/images/paradise-motel-day.png
# Enter night image URI: https://storage.googleapis.com/flunks_public/images/paradise-motel-night.png
```

### Direct Script Test

```bash
flow scripts execute cadence/scripts/paradise-motel-get-image.cdc \
  --arg Address:YOUR_TESTNET_ADDRESS \
  --arg String:"https://storage.googleapis.com/flunks_public/images/paradise-motel-day.png" \
  --arg String:"https://storage.googleapis.com/flunks_public/images/paradise-motel-night.png" \
  --network testnet

# Expected output:
# {
#   "imageURI": "https://storage.googleapis.com/flunks_public/images/paradise-motel-day.png",
#   "timeContext": "day",
#   "isDaytime": true,
#   "localHour": 14,
#   "timezone": -5,
#   "hasProfile": true
# }
```

---

## 🗄️ Supabase Configuration

### Create Table

```sql
CREATE TABLE paradise_motel_images (
  id BIGSERIAL PRIMARY KEY,
  nft_id INTEGER NOT NULL UNIQUE,
  room_number INTEGER,
  day_image_uri TEXT NOT NULL DEFAULT 'https://storage.googleapis.com/flunks_public/images/paradise-motel-day.png',
  night_image_uri TEXT NOT NULL DEFAULT 'https://storage.googleapis.com/flunks_public/images/paradise-motel-night.png',
  level VARCHAR(50) DEFAULT 'Paradise Motel',
  special_features JSONB,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_nft_id ON paradise_motel_images(nft_id);
```

### Insert Sample Data

```sql
-- Insert Paradise Motel NFTs with your production images
INSERT INTO paradise_motel_images (nft_id, room_number, day_image_uri, night_image_uri, special_features)
VALUES
  (101, 101, 
   'https://storage.googleapis.com/flunks_public/images/paradise-motel-day.png',
   'https://storage.googleapis.com/flunks_public/images/paradise-motel-night.png',
   '["Ocean View", "Mini Bar", "24hr Room Service"]'::jsonb),
  (102, 102,
   'https://storage.googleapis.com/flunks_public/images/paradise-motel-day.png',
   'https://storage.googleapis.com/flunks_public/images/paradise-motel-night.png',
   '["Pool Access", "King Bed"]'::jsonb),
  (103, 103,
   'https://storage.googleapis.com/flunks_public/images/paradise-motel-day.png',
   'https://storage.googleapis.com/flunks_public/images/paradise-motel-night.png',
   '["Mountain View", "Balcony"]'::jsonb);

-- Verify
SELECT * FROM paradise_motel_images;
```

---

## 🌐 Website API Integration

### API Route (Next.js)

**File**: `app/api/paradise-motel/image/route.ts`

```typescript
import * as fcl from "@onflow/fcl"

// Configure FCL for testnet
fcl.config()
  .put("accessNode.api", "https://rest-testnet.onflow.org")
  .put("flow.network", "testnet")

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url)
  const ownerAddress = searchParams.get("owner")
  const nftId = searchParams.get("nftId")

  if (!ownerAddress) {
    return Response.json({ error: "Missing owner address" }, { status: 400 })
  }

  try {
    // Fetch image URIs from Supabase (or use defaults)
    const dayImageURI = "https://storage.googleapis.com/flunks_public/images/paradise-motel-day.png"
    const nightImageURI = "https://storage.googleapis.com/flunks_public/images/paradise-motel-night.png"

    // Query blockchain for current image
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
        "Cache-Control": "public, max-age=3600",
        "Access-Control-Allow-Origin": "*"
      }
    })
  } catch (error) {
    console.error("Paradise Motel API error:", error)
    return Response.json(
      { 
        error: "Failed to resolve image",
        message: error instanceof Error ? error.message : "Unknown error"
      },
      { status: 500 }
    )
  }
}
```

---

## 🎨 React Component

**File**: `components/ParadiseMotelNFT.tsx`

```typescript
'use client'

import { useEffect, useState } from 'react'
import Image from 'next/image'

interface ParadiseMotelNFTProps {
  ownerAddress: string
  nftId: number
  roomNumber?: number
}

interface ImageData {
  imageURI: string
  timeContext: 'day' | 'night'
  isDaytime: boolean
  localHour: number
  timezone: number
  hasProfile: boolean
}

export function ParadiseMotelNFT({ 
  ownerAddress, 
  nftId,
  roomNumber 
}: ParadiseMotelNFTProps) {
  const [imageData, setImageData] = useState<ImageData | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    async function fetchImage() {
      try {
        setLoading(true)
        const params = new URLSearchParams({
          owner: ownerAddress,
          nftId: nftId.toString()
        })
        
        const res = await fetch(`/api/paradise-motel/image?${params}`)
        if (!res.ok) throw new Error('Failed to fetch image')
        
        const data = await res.json()
        setImageData(data)
        setError(null)
      } catch (err) {
        console.error('Failed to fetch Paradise Motel image:', err)
        setError(err instanceof Error ? err.message : 'Unknown error')
      } finally {
        setLoading(false)
      }
    }

    fetchImage()
    
    // Refresh every hour to catch day/night transitions
    const interval = setInterval(fetchImage, 3600000)
    return () => clearInterval(interval)
  }, [ownerAddress, nftId])

  if (loading) {
    return (
      <div className="paradise-motel-nft loading">
        <div className="skeleton-image" />
        <p>Loading Paradise Motel...</p>
      </div>
    )
  }

  if (error) {
    return (
      <div className="paradise-motel-nft error">
        <p>Error loading NFT: {error}</p>
      </div>
    )
  }

  if (!imageData) {
    return null
  }

  return (
    <div className={`paradise-motel-nft ${imageData.timeContext}`}>
      <div className="image-container">
        <Image 
          src={imageData.imageURI}
          alt={`Paradise Motel ${roomNumber ? `Room #${roomNumber}` : `#${nftId}`}`}
          width={500}
          height={500}
          className="nft-image"
          priority
        />
        
        <div className="time-overlay">
          <span className="time-icon">
            {imageData.isDaytime ? '🌅' : '🌙'}
          </span>
          <span className="time-context">
            {imageData.timeContext === 'day' ? 'Daytime' : 'Nighttime'}
          </span>
        </div>
      </div>
      
      <div className="nft-details">
        <h3>Paradise Motel {roomNumber ? `Room #${roomNumber}` : `#${nftId}`}</h3>
        <div className="metadata">
          <div className="meta-item">
            <span className="label">Local Time:</span>
            <span className="value">
              {imageData.localHour}:00 {imageData.isDaytime ? 'AM/PM' : 'PM/AM'}
            </span>
          </div>
          {imageData.hasProfile && (
            <div className="meta-item">
              <span className="label">Timezone:</span>
              <span className="value">UTC{imageData.timezone >= 0 ? '+' : ''}{imageData.timezone}</span>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
```

---

## 📝 NFT Metadata for Minting

When minting Paradise Motel NFTs in SemesterZero:

```cadence
// In your minting transaction
let nft <- create SemesterZero.NFT(
    id: nextNFTID,
    name: "Paradise Motel Room #101",
    description: "A cozy room at Paradise Motel with dynamic day/night views",
    thumbnail: "https://storage.googleapis.com/flunks_public/images/paradise-motel-day.png",
    attributes: {
        "type": "paradise-motel",
        "level": "Paradise Motel",
        "roomNumber": "101",
        "dayImageURI": "https://storage.googleapis.com/flunks_public/images/paradise-motel-day.png",
        "nightImageURI": "https://storage.googleapis.com/flunks_public/images/paradise-motel-night.png",
        "hasTimeVariant": "true"
    }
)
```

---

## 🧪 Testing Checklist

- [ ] Images load correctly in browser
- [ ] Day image shows during daytime hours (6 AM - 6 PM local)
- [ ] Night image shows during nighttime hours (6 PM - 6 AM local)
- [ ] Timezone calculation works for different users
- [ ] API caching works (check network tab)
- [ ] Images work on mobile and desktop

### Test Image Access

```bash
# Test day image
curl -I https://storage.googleapis.com/flunks_public/images/paradise-motel-day.png
# Should return: HTTP/2 200

# Test night image
curl -I https://storage.googleapis.com/flunks_public/images/paradise-motel-night.png
# Should return: HTTP/2 200

# Download and view locally
curl https://storage.googleapis.com/flunks_public/images/paradise-motel-day.png -o test-day.png
open test-day.png  # macOS

curl https://storage.googleapis.com/flunks_public/images/paradise-motel-night.png -o test-night.png
open test-night.png  # macOS
```

---

## 🎯 Next Steps

### 1. Deploy Contracts to Testnet
```bash
# Follow TESTNET-DEPLOYMENT-GUIDE.md
flow accounts add-contract ParadiseMotel \
  ./cadence/contracts/ParadiseMotel.cdc \
  --network testnet \
  --signer your-testnet-account
```

### 2. Test with Your Production Images
```bash
./paradise-motel.sh
# Choose option 1
# Use the Google Cloud Storage URLs
```

### 3. Set Up Supabase Table
```sql
-- Run the SQL above to create paradise_motel_images table
-- Insert your NFT data with the production image URLs
```

### 4. Create API Route
```typescript
// Add the API route to your Next.js app
// Update CONTRACT_ADDRESS with your testnet deployment
```

### 5. Integrate in Website
```typescript
// Add ParadiseMotelNFT component to your NFT gallery
// Test day/night switching at 6 AM and 6 PM
```

---

## 🔍 Verification

Your images are already:
- ✅ Hosted on Google Cloud Storage
- ✅ Publicly accessible
- ✅ Using HTTPS
- ✅ Ready for production use

**No additional image hosting setup needed!** You can start testing immediately after contract deployment.

---

## 💡 Image URL Variables for Easy Reference

```bash
# For use in scripts and testing
export PARADISE_MOTEL_DAY_IMAGE="https://storage.googleapis.com/flunks_public/images/paradise-motel-day.png"
export PARADISE_MOTEL_NIGHT_IMAGE="https://storage.googleapis.com/flunks_public/images/paradise-motel-night.png"

# Test
echo $PARADISE_MOTEL_DAY_IMAGE
echo $PARADISE_MOTEL_NIGHT_IMAGE
```

---

## 🎉 Ready to Deploy!

Your Paradise Motel images are production-ready. When you deploy the ParadiseMotel contract, use these exact URLs for testing and production.

**Image URLs**: ✅ Confirmed  
**Hosting**: ✅ Google Cloud Storage  
**Access**: ✅ Public  
**Status**: ✅ Ready for testnet deployment

Next step: Follow `TESTNET-DEPLOYMENT-GUIDE.md` to deploy contracts! 🚀
