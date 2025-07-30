import NonFungibleToken from 0x1d7e57aa55817448
import SimpleFlunksV2 from 0xbfffec679fff3a94

transaction(
    recipientAddress: Address,
    name: String,
    description: String,
    image: String
) {
    
    let minter: &SimpleFlunksV2.Admin
    
    prepare(signer: auth(BorrowValue) &Account) {
        self.minter = signer.storage.borrow<&SimpleFlunksV2.Admin>(from: SimpleFlunksV2.AdminStoragePath)
            ?? panic("Account does not store an object at the specified path")
    }
    
    execute {
        let recipient = getAccount(recipientAddress)
        let receiverRef = recipient.capabilities.borrow<&{NonFungibleToken.CollectionPublic}>(SimpleFlunksV2.CollectionPublicPath)
            ?? panic("Could not get receiver reference to the NFT Collection")
        
        self.minter.mintNFT(
            recipient: receiverRef,
            name: name,
            description: description,
            image: image
        )
    }
}
