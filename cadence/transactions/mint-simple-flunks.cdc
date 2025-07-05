import SimpleFlunks from 0xf8d6e0586b0a20c7
import NonFungibleToken from 0xf8d6e0586b0a20c7

// Step 2: Transaction to mint NFT using admin wallet
transaction(
    recipientAddress: Address,
    name: String,
    description: String,
    image: String
) {
    let admin: &SimpleFlunks.Admin
    let recipientCollectionRef: &{NonFungibleToken.CollectionPublic}

    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Get the admin resource from storage - This is Step 3: Admin wallet calling the transaction
        self.admin = signer.storage.borrow<&SimpleFlunks.Admin>(from: SimpleFlunks.AdminStoragePath)
            ?? panic("Could not borrow SimpleFlunks Admin resource")

        // Get the recipient's collection capability
        let recipientAccount = getAccount(recipientAddress)
        self.recipientCollectionRef = recipientAccount.capabilities.get<&{NonFungibleToken.CollectionPublic}>(SimpleFlunks.CollectionPublicPath)
            .borrow()
            ?? panic("Could not borrow recipient's NFT collection reference")
    }

    execute {
        // Step 1 & 2: Admin resource calls mintNFT function ✅
        self.admin.mintNFT(
            recipient: self.recipientCollectionRef,
            name: name,
            description: description,
            image: image
        )
        
        log("✅ Successfully minted SimpleFlunks NFT:")
        log("   Name: ".concat(name))
        log("   Description: ".concat(description))
        log("   Recipient: ".concat(recipientAddress.toString()))
        log("   Total Supply: ".concat(SimpleFlunks.totalSupply.toString()))
    }
}
