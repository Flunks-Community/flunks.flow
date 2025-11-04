import SemesterZero from "../contracts/SemesterZero.cdc"

/// ADMIN: Batch airdrop GUM directly to user accounts
/// This bypasses the claim system and directly deposits GUM
/// Useful for guaranteed airdrops to specific addresses
///
/// USAGE:
/// flow transactions send ./cadence/transactions/halloween-batch-airdrop.cdc \
///   --arg Address:0x1234... --arg UFix64:100.0 \
///   --arg Address:0x5678... --arg UFix64:150.0 \
///   --signer admin-account

transaction(recipients: [Address], amounts: [UFix64]) {
    
    prepare(admin: auth(BorrowValue) &Account) {
        // Verify arrays are same length
        assert(
            recipients.length == amounts.length,
            message: "Recipients and amounts arrays must be same length"
        )
        
        // Borrow admin resource
        let adminRef = admin.storage.borrow<&SemesterZero.Admin>(
            from: SemesterZero.AdminStoragePath
        ) ?? panic("Could not borrow admin resource")
        
        // Airdrop to each recipient
        var i = 0
        while i < recipients.length {
            let recipient = recipients[i]
            let amount = amounts[i]
            
            // Get recipient's current balance
            let account = getAccount(recipient)
            let gumAccount = account.capabilities
                .get<&{SemesterZero.GumAccountPublic}>(SemesterZero.GumAccountPublicPath)
                .borrow()
            
            if let gum = gumAccount {
                let oldBalance = gum.getBalance()
                let newBalance = oldBalance + amount
                
                // Sync the new balance (this adds the airdrop amount)
                adminRef.syncUserBalance(
                    userAddress: recipient,
                    newBalance: newBalance
                )
                
                log("Airdropped ".concat(amount.toString()).concat(" GUM to ").concat(recipient.toString()))
            } else {
                log("WARNING: ".concat(recipient.toString()).concat(" does not have a GUM account - skipped"))
            }
            
            i = i + 1
        }
    }
    
    execute {
        log("Halloween batch airdrop complete! 🎃👻")
        log("Total recipients: ".concat(recipients.length.toString()))
    }
}
