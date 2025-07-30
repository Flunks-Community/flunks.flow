import NonFungibleToken from 0x1d7e57aa55817448
import SimpleFlunks from 0xbfffec679fff3a94

transaction {
    let adminRef: &SimpleFlunks.Admin

    prepare(signer: auth(BorrowValue) &Account) {
        // Get a reference to the Admin resource in storage
        self.adminRef = signer.storage.borrow<&SimpleFlunks.Admin>(from: SimpleFlunks.AdminStoragePath)
            ?? panic("Could not borrow a reference to the Admin resource")
    }

    execute {
        // Get the recipient's public collection reference
        let recipient = getAccount(0xbfffec679fff3a94)
        let receiverRef = recipient.capabilities.borrow<&SimpleFlunks.Collection>(SimpleFlunks.CollectionPublicPath)
            ?? panic("Could not borrow receiver collection reference")

        // Mint the NFT with backpack image
        self.adminRef.mintNFT(
            recipient: receiverRef,
            name: "Flunks Mainnet Edition #2",
            description: "The official Flunks NFT on Flow mainnet with working image! �",
            image: "https://storage.googleapis.com/flunks_public/backpack/1c023bb17a570b7e114e35d195035e41fc60a5c3c60933daf1c780f51abfe24d.png"
        )
    }
}
