// Transfer a Flunks NFT from one account to another
import Flunks from 0x807c3d470888cc48
import NonFungibleToken from 0x1d7e57aa55817448

transaction(recipientAddress: Address, nftID: UInt64) {
    
    let senderCollection: auth(NonFungibleToken.Withdraw) &Flunks.Collection
    let recipientCollection: &{NonFungibleToken.CollectionPublic}
    
    prepare(signer: auth(BorrowValue) &Account) {
        // Get sender's collection
        self.senderCollection = signer.storage.borrow<auth(NonFungibleToken.Withdraw) &Flunks.Collection>(
            from: Flunks.CollectionStoragePath
        ) ?? panic("Could not borrow sender's Flunks collection")
        
        // Get recipient's public collection capability
        let recipient = getAccount(recipientAddress)
        self.recipientCollection = recipient.capabilities.borrow<&{NonFungibleToken.CollectionPublic}>(
            Flunks.CollectionPublicPath
        ) ?? panic("Could not borrow recipient's Flunks collection. Make sure they have initialized their collection.")
    }
    
    execute {
        // Withdraw the NFT from sender
        let nft <- self.senderCollection.withdraw(withdrawID: nftID)
        
        // Deposit to recipient
        self.recipientCollection.deposit(token: <-nft)
        
        log("Successfully transferred Flunks NFT #".concat(nftID.toString()))
    }
}