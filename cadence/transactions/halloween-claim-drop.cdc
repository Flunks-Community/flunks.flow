import SemesterZero from "../contracts/SemesterZero.cdc"

/// Claim the Halloween Special Drop
/// User must have a GUM account already set up
///
/// USAGE (from website or user):
/// flow transactions send ./cadence/transactions/halloween-claim-drop.cdc \
///   --arg UInt64:1 \
///   --signer user-account

transaction(dropID: UInt64) {
    
    let gumAccountRef: &SemesterZero.GumAccount
    
    prepare(user: auth(BorrowValue) &Account) {
        // Borrow user's GUM account
        self.gumAccountRef = user.storage.borrow<&SemesterZero.GumAccount>(
            from: SemesterZero.GumAccountStoragePath
        ) ?? panic("Could not borrow GUM account. Please set up your account first.")
    }
    
    execute {
        // Claim the drop!
        SemesterZero.claimSpecialDrop(
            dropID: dropID,
            gumAccount: self.gumAccountRef
        )
        
        log("Halloween drop claimed successfully! 🎃")
        log("New balance: ".concat(self.gumAccountRef.getBalance().toString()))
    }
}
