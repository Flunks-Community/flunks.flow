# Example Flunks NFT Traits Structure

## Core Traits (Common for Character NFTs)
1. **Background** - String values like "City", "Forest", "Space", "Underwater"
2. **Body** - String values like "Blue", "Green", "Pink", "Golden"
3. **Eyes** - String values like "Normal", "Laser", "Sleepy", "Winking"
4. **Mouth** - String values like "Smile", "Frown", "Open", "Tongue"
5. **Hat** - String values like "None", "Cap", "Crown", "Helmet"
6. **Accessory** - String values like "None", "Glasses", "Earrings", "Necklace"

## Special Traits
7. **Rarity** - String values like "Common", "Uncommon", "Rare", "Epic", "Legendary"
8. **Level** - Number values like 1, 2, 3, etc.
9. **Power** - Number values like 100, 250, 500, etc.
10. **Generation** - String values like "Gen 1", "Gen 2", etc.

## Edition Information
11. **Edition Number** - Number (e.g., 1 of 1000)
12. **Max Edition** - Number (e.g., 1000)

## External Links
13. **External URL** - Link to character profile page
14. **Animation URL** - Link to animated version

# File Structure in Google Cloud Storage:
/flunks_public/
  ├── images/
  │   ├── flunk-001.png
  │   ├── flunk-002.png
  │   └── ...
  ├── animations/
  │   ├── flunk-001.mp4
  │   ├── flunk-002.mp4
  │   └── ...
  └── metadata/
      ├── flunk-001.json
      ├── flunk-002.json
      └── ...
