import SimpleFlunksWithTraits from 0xf8d6e0586b0a20c7
import NonFungibleToken from 0xf8d6e0586b0a20c7

transaction(recipient: Address) {
    prepare(acct: auth(Storage) &Account) {
        // Borrow the admin resource
        let admin = acct.storage.borrow<&SimpleFlunksWithTraits.Admin>(from: SimpleFlunksWithTraits.AdminStoragePath)
            ?? panic("Could not borrow admin resource")
        
        // Get the recipient's collection
        let recipientCollection = getAccount(recipient)
            .capabilities.borrow<&{NonFungibleToken.CollectionPublic}>(SimpleFlunksWithTraits.CollectionPublicPath)
            ?? panic("Could not borrow recipient collection")
        
        // Create sample traits for testing
        let traits = [
            SimpleFlunksWithTraits.Trait(name: "Background", value: "Space", displayType: nil, rarity: nil),
            SimpleFlunksWithTraits.Trait(name: "Body", value: "Golden", displayType: nil, rarity: nil),
            SimpleFlunksWithTraits.Trait(name: "Eyes", value: "Laser", displayType: nil, rarity: nil),
            SimpleFlunksWithTraits.Trait(name: "Mouth", value: "Smile", displayType: nil, rarity: nil),
            SimpleFlunksWithTraits.Trait(name: "Hat", value: "Crown", displayType: nil, rarity: nil),
            SimpleFlunksWithTraits.Trait(name: "Accessory", value: "Glasses", displayType: nil, rarity: nil),
            SimpleFlunksWithTraits.Trait(name: "Rarity", value: "Legendary", displayType: nil, rarity: nil),
            SimpleFlunksWithTraits.Trait(name: "Level", value: 25, displayType: "number", rarity: nil),
            SimpleFlunksWithTraits.Trait(name: "Power", value: 500, displayType: "number", rarity: nil),
            SimpleFlunksWithTraits.Trait(name: "Generation", value: "Gen 1", displayType: nil, rarity: nil)
        ]
        
        // Mint the NFT
        admin.mintNFT(
            recipient: recipientCollection,
            name: "Epic Flunk #1",
            description: "A legendary flunk with rare traits",
            image: "https://storage.googleapis.com/flunks_public/images/flunk-001.png",
            traits: traits,
            externalURL: "https://flunks.com/flunk-001",
            animationURL: "https://storage.googleapis.com/flunks_public/animations/flunk-001.mp4",
            edition: 1,
            maxEdition: 1000
        )
        
        log("NFT minted successfully with traits!")
    }
}
