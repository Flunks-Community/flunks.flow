import Flunks from 0xf8d6e0586b0a20c7

transaction {
  prepare(acct: &Account) {
    let metadata: {String: String} = {
      "uri": "https://storage.googleapis.com/flunks_public/images/flunk_1.png",
      "pixelUri": "https://storage.googleapis.com/flunks_public/flunks/pixel_flunk_1.png",
      "rarity": "Epic",
      "grade": "A+"
    }

    let templateID = Flunks.createTemplate(
      name: "Test Flunk",
      description: "Your first Flunk NFT!",
      metadata: metadata
    )

    log("✅ Created Flunks template with ID ".concat(templateID.toString()))
  }
}
