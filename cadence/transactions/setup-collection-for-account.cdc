import Flunks from 0x807c3d470888cc48
import NonFungibleToken from 0x1d7e57aa55817448

transaction(recipientAddress: Address) {
  prepare(signer: auth(BorrowValue) &Account) {
    let recipient = getAccount(recipientAddress)
    
    // Check if collection already exists
    if recipient.capabilities.borrow<&Flunks.Collection>(Flunks.CollectionPublicPath) != nil {
      log("ℹ️  Collection already exists on account ".concat(recipientAddress.toString()))
      return
    }
    
    log("❌ Cannot initialize collection on another account without auth")
    log("The recipient account needs to run the setup transaction themselves or have FLOW tokens")
  }
}
