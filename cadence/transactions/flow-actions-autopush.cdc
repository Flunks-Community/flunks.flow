import SemesterZero from "../contracts/SemesterZero.cdc"
import SemesterZeroFlowActions from "../contracts/SemesterZeroFlowActions.cdc"

/// Halloween Autopush Transaction using Flow Actions
/// Automatically pushes Supabase GUM balance + Halloween bonus to user's blockchain wallet
///
/// This is called by admin (via API) for each eligible user
///
/// USAGE:
/// flow transactions send ./cadence/transactions/flow-actions-autopush.cdc \
///   --arg Address:0x1234567890123456 \
///   --arg UFix64:50.0 \
///   --arg UFix64:100.0 \
///   --arg String:"halloween_2025_user_0x1234" \
///   --signer admin-account

transaction(
    userAddress: Address,      // User to receive GUM
    supabaseBalance: UFix64,   // Their current Supabase GUM balance
    halloweenBonus: UFix64,    // Halloween bonus (e.g., 100 GUM)
    workflowID: String         // Unique ID for tracing (e.g., "halloween_2025_user_0x1234")
) {
    
    prepare(admin: auth(Storage, BorrowValue) &Account) {
        // Verify user has GumAccount set up
        let account = getAccount(userAddress)
        let gumAccountCap = account.capabilities
            .get<&SemesterZero.GumAccount>(SemesterZero.GumAccountPublicPath)
        
        assert(
            gumAccountCap.check(),
            message: "User ".concat(userAddress.toString()).concat(" does not have a GUM account set up")
        )
        
        // Execute Flow Actions workflow
        SemesterZeroFlowActions.executeAutopush(
            userAddress: userAddress,
            supabaseBalance: supabaseBalance,
            bonus: halloweenBonus,
            workflowID: workflowID
        )
    }
    
    execute {
        let totalAmount = supabaseBalance + halloweenBonus
        
        log("🎃 Halloween Autopush Complete!")
        log("   User: ".concat(userAddress.toString()))
        log("   Supabase Balance: ".concat(supabaseBalance.toString()).concat(" GUM"))
        log("   Halloween Bonus: ".concat(halloweenBonus.toString()).concat(" GUM"))
        log("   Total Deposited: ".concat(totalAmount.toString()).concat(" GUM"))
        log("   Workflow ID: ".concat(workflowID))
    }
}
