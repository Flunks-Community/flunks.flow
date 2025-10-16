// Transfer GUM to another user (on-chain)

import GumDropsHybrid from "../../contracts/GumDropsHybrid.cdc"

transaction(recipient: Address, amount: UFix64, message: String?) {
    let gumAccount: auth(GumDropsHybrid.GumAccount) &GumDropsHybrid.GumAccount
    
    prepare(signer: auth(Storage, BorrowValue) &Account) {
        self.gumAccount = signer.storage.borrow<auth(GumDropsHybrid.GumAccount) &GumDropsHybrid.GumAccount>(
            from: GumDropsHybrid.GumAccountStoragePath
        ) ?? panic("No GUM account found. Run setup-gum-account.cdc first")
    }
    
    execute {
        // Transfer GUM on-chain
        self.gumAccount.transfer(
            amount: amount,
            to: recipient,
            message: message
        )
        
        log("Transferred ".concat(amount.toString()).concat(" GUM to ").concat(recipient.toString()))
        if let msg = message {
            log("Message: ".concat(msg))
        }
    }
    
    post {
        self.gumAccount.getInfo().balance >= 0.0: "Invalid balance after transfer"
    }
}
