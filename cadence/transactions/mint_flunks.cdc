import Flunks from 0xf8d6e0586b0a20c7
import NonFungibleToken from 0xf8d6e0586b0a20c7

transaction(templateID: UInt64, recipient: Address) {
    prepare(acct: AuthAccount) {
        let admin = acct.borrow<&Flunks.Admin>(from: Flunks.AdminStoragePath)
            ?? panic("Could not borrow Flunks.Admin resource from signer")

        let recipientAcct = getAccount(recipient)
        let collectionRef = recipientAcct
            .getCapability(Flunks.CollectionPublicPath)
            .borrow<&{NonFungibleToken.CollectionPublic}>()
            ?? panic("Could not borrow recipient's NFT collection reference")

        admin.mintNFT(templateID: templateID, recipient: collectionRef)
    }
}
