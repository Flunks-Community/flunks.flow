// This transaction is called by the ADMIN (backend) to withdraw GUM from website balance to user's wallet
// User requests withdrawal on website → Backend calls this transaction with admin signature

import GUMDrops from "../../contracts/GUMDrops.cdc"
import GUM from "../../contracts/GUM.cdc"
import FungibleToken from "../../contracts/FungibleToken.cdc"

transaction(recipient: Address, amount: UFix64, withdrawalID: String) {
    let admin: &GUMDrops.Admin
    
    prepare(signer: auth(Storage, BorrowValue) &Account) {
        // Admin must have Admin resource
        self.admin = signer.storage.borrow<&GUMDrops.Admin>(
            from: GUMDrops.AdminStoragePath
        ) ?? panic("Could not borrow admin resource")
    }
    
    execute {
        // This will:
        // 1. Mint GUM tokens
        // 2. Setup recipient's vault if needed
        // 3. Deposit tokens to recipient
        // 4. Emit WithdrawalProcessed event
        self.admin.withdrawGUMToWallet(
            recipient: recipient,
            amount: amount,
            withdrawalID: withdrawalID
        )
        
        log("Withdrawal processed for ".concat(recipient.toString()).concat(" - ").concat(amount.toString()).concat(" GUM"))
    }
}
