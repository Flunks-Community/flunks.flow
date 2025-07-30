import SimpleFlunks from 0xb97ea2274b0ae5d2
import NonFungibleToken from 0x631e88ae7f1d7c20

// Mint a testnet Flunks NFT with proper image for Flowty visibility
transaction(
    recipientAddress: Address,
    name: String,
    description: String,
    image: String
) {
    let admin: &SimpleFlunks.Admin
    let recipientCollectionRef: &{NonFungibleToken.CollectionPublic}

    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Get the admin resource from storage
        self.admin = signer.storage.borrow<&SimpleFlunks.Admin>(from: SimpleFlunks.AdminStoragePath)
            ?? panic("Could not borrow SimpleFlunks Admin resource")

        // Get the recipient's collection capability
        let recipientAccount = getAccount(recipientAddress)
        self.recipientCollectionRef = recipientAccount.capabilities.get<&{NonFungibleToken.CollectionPublic}>(SimpleFlunks.CollectionPublicPath)
            .borrow()
            ?? panic("Could not borrow recipient's NFT collection reference")
    }

    execute {
        // Mint the NFT with the verified Flunks image
        self.admin.mintNFT(
            recipient: self.recipientCollectionRef,
            name: name,
            description: description,
            image: image
        )
        
        log("✅ Successfully minted testnet SimpleFlunks NFT:")
        log("   Name: ".concat(name))
        log("   Description: ".concat(description))
        log("   Image: ".concat(image))
        log("   Recipient: ".concat(recipientAddress.toString()))
        log("   Total Supply: ".concat(SimpleFlunks.totalSupply.toString()))
        log("🔗 View on Flow Explorer: https://testnet.flowscan.org/account/".concat(recipientAddress.toString()))
    }
}
