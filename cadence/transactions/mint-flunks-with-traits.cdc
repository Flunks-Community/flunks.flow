import SimpleFlunksWithTraits from 0xf8d6e0586b0a20c7
import NonFungibleToken from 0xf8d6e0586b0a20c7

transaction(
    recipient: Address,
    name: String,
    description: String,
    image: String,
    externalURL: String?,
    animationURL: String?,
    edition: UInt64?,
    maxEdition: UInt64?,
    // Trait parameters
    traitNames: [String],
    traitValues: [String],
    traitDisplayTypes: [String?],
    traitRarities: [String?]
) {
    let admin: &SimpleFlunksWithTraits.Admin
    let recipientCollection: &{NonFungibleToken.CollectionPublic}
    
    prepare(signer: &Account) {
        // Get admin resource
        self.admin = signer.storage.borrow<&SimpleFlunksWithTraits.Admin>(
            from: SimpleFlunksWithTraits.AdminStoragePath
        ) ?? panic("Could not borrow admin resource")
        
        // Get recipient's collection
        self.recipientCollection = getAccount(recipient)
            .capabilities.borrow<&{NonFungibleToken.CollectionPublic}>(
                SimpleFlunksWithTraits.CollectionPublicPath
            ) ?? panic("Could not get receiver reference to the NFT Collection")
    }
    
    execute {
        // Build traits array
        var traits: [SimpleFlunksWithTraits.Trait] = []
        var i = 0
        while i < traitNames.length {
            let trait = SimpleFlunksWithTraits.Trait(
                name: traitNames[i],
                value: traitValues[i],
                displayType: i < traitDisplayTypes.length ? traitDisplayTypes[i] : nil,
                rarity: i < traitRarities.length ? traitRarities[i] : nil
            )
            traits.append(trait)
            i = i + 1
        }
        
        // Mint the NFT
        self.admin.mintNFT(
            recipient: self.recipientCollection,
            name: name,
            description: description,
            image: image,
            traits: traits,
            externalURL: externalURL,
            animationURL: animationURL,
            edition: edition,
            maxEdition: maxEdition
        )
        
        log("Minted NFT with traits to ".concat(recipient.toString()))
    }
}
