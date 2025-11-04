# Paradise Motel NFT - Reveal System

## 🎭 Current Setup (Unrevealed)

### Metadata (Temporary)
```json
{
  "name": "Paradise Motel",
  "description": "Awarded for completing both Slacker and Overachiever objectives in Chapter 5 of Flunks: Semester Zero",
  "achievement": "SLACKER_AND_OVERACHIEVER",
  "chapter": "5",
  "collection": "Flunks: Semester Zero",
  "rarity": "Legendary",
  "serialNumber": "1",  // 1st, 2nd, 3rd person to complete
  "revealed": "false",
  "image": "https://storage.googleapis.com/flunks_public/nfts/paradise-motel-unrevealed.png"
}
```

### NFT Fields
- **id**: Unique NFT ID (0, 1, 2, etc.)
- **serialNumber**: Mint order (1st, 2nd, 3rd to complete Chapter 5)
- **recipient**: Wallet address of owner
- **mintedAt**: Blockchain timestamp when airdropped
- **achievementType**: `SLACKER_AND_OVERACHIEVER`
- **metadata**: Dictionary (can be updated for reveal)

---

## 🎨 Reveal System

### How It Works
When you're ready to reveal the real NFT:

1. **Update the image** to the revealed version
2. **Add traits/rarity** based on serial number or other criteria
3. **Change `revealed` flag** to `"true"`
4. **Keep serial number** so early completers can have special traits

### Admin Function
```cadence
// Reveal a single user's NFT
Admin.revealChapter5NFT(
  userAddress: 0x123...,
  newMetadata: {
    "name": "Paradise Motel",
    "description": "...",
    "revealed": "true",
    "rarity": "Legendary",
    "serialNumber": "1",
    "trait_early_bird": "First 10",  // NEW
    "trait_room": "Room 237",        // NEW
    "image": "https://storage.googleapis.com/flunks_public/nfts/paradise-motel-revealed.png"
  }
)
```

---

## 🏆 Tier System (90s Nostalgia)

### Based on Serial Number (Completion Order)

| Serial # | Tier        |
|----------|-------------|
| 1-5      | **Pager**   |
| 6-15     | **Discman** |
| 16-30    | **Tamagotchi** |
| 31-50    | **GameBoy** |
| 51+      | **Dial-Up** |

**Auto-assigned at mint time** - purely based on who completes Chapter 5 objectives first!

### Example Metadata
```json
{
  "serialNumber": "3",
  "tier": "Pager"
}
```

---

## 🎨 Additional Trait Ideas (For Reveal)

### Room Numbers (Random or based on wallet hash)
```
Room 237  (Horror movie reference)
Room 420  (Slacker culture)
Room 666  (Edgy)
Room 13   (Unlucky)
Room 101  (Classic)
```

### Time-Based Traits (when they completed)
```
"Completed During Halloween"
"Midnight Slacker" (completed 12 AM - 6 AM)
"Day One Achiever" (Oct 31)
"Last Minute Hero" (Nov 2-3)
```

### Combo Traits (could be randomized)
```
trait_vibe:     "Creepy", "Chill", "Chaotic", "Mysterious"
trait_weather:  "Foggy Night", "Neon Glow", "Thunderstorm", "Starry Sky"
trait_guest:    "Solo Traveler", "Road Tripper", "Runaway", "Lost Soul"
trait_era:      "80s Neon", "90s Grunge", "Y2K", "Retro Future"
```

---

## 🖼️ Image Variants (Ideas)

### Unrevealed (Current)
- Generic "Paradise Motel" sign
- Silhouette/mystery aesthetic
- "Coming Soon" vibe

### Revealed (Future)
Could have **multiple variants** based on traits:

**Day Version** (6 AM - 6 PM holders):
- Bright motel in daylight
- Palm trees, clear sky
- Vintage postcard aesthetic

**Night Version** (6 PM - 6 AM holders):
- Neon sign glowing
- Dark sky, stars
- Creepy/mysterious vibe (matches The Freaks audio)

**Rare Variants**:
- Animated GIF (lightning flash, neon flicker)
- Different room windows lit up
- Easter eggs in the image based on serial number

---

## 🔧 Reveal Transaction Template

```cadence
import SemesterZero from 0x807c3d470888cc48

transaction(userAddress: Address) {
    let adminRef: &SemesterZero.Admin
    
    prepare(signer: auth(Storage) &Account) {
        self.adminRef = signer.storage.borrow<&SemesterZero.Admin>(
            from: SemesterZero.AdminStoragePath
        ) ?? panic("Could not borrow Admin reference")
    }
    
    execute {
        // Example: Reveal with early bird trait
        let newMetadata = {
            "name": "Paradise Motel",
            "description": "A legendary motel from the darkest chapter of Semester Zero. Only true slackers and overachievers found this place.",
            "achievement": "SLACKER_AND_OVERACHIEVER",
            "chapter": "5",
            "collection": "Flunks: Semester Zero",
            "revealed": "true",
            "rarity": "Legendary",
            "serialNumber": "1",
            "trait_tier": "OG Slacker",
            "trait_room": "Room 237",
            "trait_vibe": "Creepy",
            "trait_time": "Midnight Slacker",
            "image": "https://storage.googleapis.com/flunks_public/nfts/paradise-motel-revealed-night.png"
        }
        
        self.adminRef.revealChapter5NFT(
            userAddress: userAddress,
            newMetadata: newMetadata
        )
        
        log("Paradise Motel NFT revealed for: ".concat(userAddress.toString()))
    }
}
```

---

## 📊 Bulk Reveal Script

```bash
#!/bin/bash
# Reveal all Paradise Motel NFTs at once

# Get all Chapter 5 NFT holders
HOLDERS=$(flow scripts execute <<'EOF'
import SemesterZero from 0x807c3d470888cc48

access(all) fun main(): [Address] {
  // Return list of all Chapter 5 NFT holders
  return []  // TODO: implement query
}
EOF
)

# For each holder, reveal with appropriate traits
for HOLDER in $HOLDERS; do
  # Generate metadata based on serial number, wallet, etc.
  # Call reveal transaction
  flow transactions send reveal-chapter5-nft.cdc $HOLDER --signer=mainnet-account
done
```

---

## 💡 Creative Ideas

### 1. Tiered Reveal
- Reveal early completers first (create FOMO)
- Build hype with each wave
- Tweet out reveals in batches

### 2. Interactive Reveal
- Users click a button on flunks.flow
- Transaction shows "checking in to Paradise Motel"
- Image updates instantly in their wallet

### 3. Mystery Traits
- Don't announce all traits upfront
- Some are discoverable (e.g., "Secret Room" for specific serial #s)
- Community tries to figure out trait system

### 4. Day/Night Variants Match User Timezone
- Read their UserProfile.timezone from blockchain
- Assign day or night image based on when they usually visit
- Ties into the Paradise Motel day/night system!

---

## 📝 Next Steps

1. **Design unrevealed image** → Upload to `paradise-motel-unrevealed.png`
2. **Plan trait system** → Decide which traits and how to assign
3. **Design revealed variants** → Create 2-5 image variants
4. **Write reveal transactions** → One for single user, one for bulk
5. **Pick reveal date** → After Halloween or wait for hype moment?
6. **Announce to community** → "Paradise Motel NFTs will reveal soon..."

---

## 🎯 Remember

- **Serial numbers are permanent** (1st, 2nd, 3rd to complete)
- **Metadata can be updated** anytime via Admin
- **Images should be hosted** before reveal
- **Traits make it collectible** - rare combos = value
- **Tie it to the story** - Why Paradise Motel? What's the lore?
