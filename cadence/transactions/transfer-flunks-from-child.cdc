// Transfer Flunks from a Hybrid Custody child account
import HybridCustody from 0xd8a7e05a7ac670c0
import Flunks from 0x807c3d470888cc48
import NonFungibleToken from 0x1d7e57aa55817448

transaction(childAddress: Address, recipientAddress: Address, nftID: UInt64) {
    
    prepare(parentSigner: auth(BorrowValue) &Account) {
        // Get the HybridCustody manager from the parent account
        let manager = parentSigner.storage.borrow<auth(HybridCustody.Manage) &HybridCustody.Manager>(
            from: HybridCustody.ManagerStoragePath
        ) ?? panic("Could not borrow HybridCustody Manager")
        
        // Get the child account reference
        let childAcct = manager.borrowAccount(addr: childAddress) 
            ?? panic("Could not borrow child account")
        
        // Try to get the provider capability from the child account's delegator
        let providerType = Type<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Provider}>()
        let providerCap = childAcct.getPrivateCapFromDelegator(type: providerType)
            ?? panic("Could not get provider capability from child account delegator")
        
        let typedCap = providerCap as! Capability<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Provider}>
        let provider = typedCap.borrow() 
            ?? panic("Could not borrow provider from child")
        
        // Withdraw the NFT from child account
        let nft <- provider.withdraw(withdrawID: nftID)
        
        // Get recipient's collection
        let recipient = getAccount(recipientAddress)
        let recipientCollection = recipient.capabilities.borrow<&{NonFungibleToken.CollectionPublic}>(
            Flunks.CollectionPublicPath
        ) ?? panic("Could not borrow recipient's collection. Make sure they have initialized their Flunks collection.")
        
        // Deposit to recipient
        recipientCollection.deposit(token: <-nft)
        
        log("Successfully transferred Flunks NFT #".concat(nftID.toString()).concat(" from child account ").concat(childAddress.toString()).concat(" to ").concat(recipientAddress.toString()))
    }
}